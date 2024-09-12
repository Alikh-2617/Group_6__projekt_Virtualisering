
Vagrant.configure("2") do |config|

  # Definition of the Web Server VM
  config.vm.define "webserver" do |web|
    web.vm.box = "ubuntu/bionic64"
    web.vm.hostname = "webserver"
    web.vm.network "private_network", type: "dhcp"
    web.vm.network "forwarded_port", guest: 80, host: 8080
    web.vm.network "forwarded_port", guest: 443, host: 8443
    web.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "100"]
    end
  end
    
    # Public network to access the web server externally on port 80 and 443
    web.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"
    
    # Private network for database access
    web.vm.network "private_network", ip: "192.168.33.10"
    
    # Provisioning: Installing Nginx
    web.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y nginx
      sudo ufw allow 'Nginx Full'
     SHELL
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/bionic64"
    db.vm.hostname = "dbserver"
    db.vm.network "private_network", type: "dhcp"
    db.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
      vb.cpus = 4
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "100"]
    end
  end

  # Load balancer VM
  config.vm.define "loadbalancer" do |lb|
    lb.vm.box = "ubuntu/bionic64"
    lb.vm.hostname = "loadbalancer"
    lb.vm.network "private_network", type: "dhcp"
    lb.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "100"]
    end
  end
    
    # Public network for nå load balancer genom
    lb.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"
    
    # Private network for kommunikatin med web servern
    lb.vm.network "private_network", ip: "192.168.33.12"
    
    # HAProxy for load balancing
    lb.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y haproxy
      sudo ufw allow 80
      sudo ufw allow 443
      echo '
      frontend http_front
          bind *:80
          default_backend servers

      backend servers
          server webserver1 192.168.33.10:80 check
      ' | sudo tee /etc/haproxy/haproxy.cfg
      sudo systemctl restart haproxy
    SHELL
  end

  # General settings 
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 2
  end

end
