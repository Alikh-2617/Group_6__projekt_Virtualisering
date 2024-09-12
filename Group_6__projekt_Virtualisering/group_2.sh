# Vagrantfile

Vagrant.configure("2") do |config|

  # Allmänt provision-script för alla maskiner
  common_setup = <<-SHELL
    # Regelbundna uppdateringar och säkerhetsuppdateringar
    cat <<EOF > /etc/cron.daily/security-updates
    #!/bin/bash
    apt-get update
    apt-get upgrade -y
    EOF

    chmod +x /etc/cron.daily/security-updates

    # Konfigurera SSH-nyckelhantering
    mkdir -p /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh
    cp /vagrant/id_rsa.pub /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
  SHELL

  # VM1: Lastbalanserare
  config.vm.define "load_balancer" do |lb|
    lb.vm.box = "ubuntu/bionic64"
    lb.vm.network "private_network", type: "dhcp"
    lb.vm.network "forwarded_port", guest: 80, host: 8080
    lb.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["createhd", "--filename", "load_balancer_disk", "--size", 10240] # 10 GB
    end
    lb.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y nginx ufw
      ufw allow 'Nginx Full'
      ufw enable
      #{common_setup}  # Kör common setup på denna maskin
    SHELL
  end

  # VM2: Webbserver
  config.vm.define "web_server" do |web|
    web.vm.box = "ubuntu/bionic64"
    web.vm.network "private_network", type: "dhcp"
    web.vm.network "forwarded_port", guest: 80, host: 8081
    web.vm.network "forwarded_port", guest: 443, host: 8443
    web.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
      vb.customize ["createhd", "--filename", "web_server_disk", "--size", 20480] # 20 GB
    end
    web.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y nginx ufw
      ufw allow 'Nginx Full'
      ufw enable
      #{common_setup}  # Kör common setup på denna maskin
    SHELL
  end

  # VM3: Databasserver
  config.vm.define "db_server" do |db|
    db.vm.box = "ubuntu/bionic64"
    db.vm.network "private_network", type: "dhcp"
    db.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
      vb.cpus = 4
      vb.customize ["createhd", "--filename", "db_server_disk", "--size", 30720] # 30 GB
    end
    db.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y postgresql 
      apt-get install -y ufw
      ufw allow from 192.168.50.4 to any port 5432
      ufw enable
      #{common_setup}  # Kör common setup på denna maskin och det 
    SHELL
  end

end
