

Vagrant.configure("2") do |config|
  
  # Definiera Webbserver (VM1)
  config.vm.define "webserver" do |webserver|
    webserver.vm.box = "ubuntu/bionic64"
    webserver.vm.hostname = "webserver"
    webserver.vm.network "private_network", type: "dhcp"
    webserver.vm.network "forwarded_port", guest: 80, host: 8080
    webserver.vm.network "forwarded_port", guest: 443, host: 8443

    # Resursallokering
    webserver.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end

    # Provisionering för uppdateringar
    webserver.vm.provision "shell", inline: <<-SHELL
      # Uppdatera och installera paket
      apt update && apt upgrade -y
      apt install -y nginx

      # Skapa uppdateringsskript
      echo '#!/bin/bash
      apt update -y
      apt upgrade -y
      apt autoremove -y
      apt clean' > /usr/local/bin/update-system.sh

      # Gör skriptet körbart
      chmod +x /usr/local/bin/update-system.sh

      # Lägg till cron-jobb
      (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/update-system.sh >> /var/log/update-system.log 2>&1") | crontab -
    SHELL
  end
    
    # Public network för att nå web server på port 80 and 443
    web.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"
    
    # Private network for database access
    web.vm.network "private_network", ip: "192.168.33.10"
    
    # Instaliera Nginx i VM Os
    web.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y nginx
      sudo ufw allow 'Nginx Full'
     SHELL
  end

    # Provisionering för uppdateringar
    databaseserver.vm.provision "shell", inline: <<-SHELL
      # Uppdatera och installera paket
      apt update && apt upgrade -y
      apt install -y mysql-server

      # Skapa uppdateringsskript
      echo '#!/bin/bash
      apt update -y
      apt upgrade -y
      apt autoremove -y
      apt clean' > /usr/local/bin/update-system.sh

      # Gör skriptet körbart
      chmod +x /usr/local/bin/update-system.sh

      # Lägg till cron-jobb
      (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/update-system.sh >> /var/log/update-system.log 2>&1") | crontab -
    SHELL
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
      
    # Skapa uppdateringsskript
      echo '#!/bin/bash
      apt update -y
      apt upgrade -y
      apt autoremove -y
      apt clean' > /usr/local/bin/update-system.sh

      # Gör skriptet körbart
      chmod +x /usr/local/bin/update-system.sh

      # Lägg till cron-jobb
      (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/update-system.sh >> /var/log/update-system.log 2>&1") | crontab -
    SHELL
  end

  # General settings eller Cron job
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 2
  end

end
