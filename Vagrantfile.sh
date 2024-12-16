# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"

config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # BalanceadorNico
  config.vm.define "balanceadorNico" do |app|
    app.vm.hostname = "balanceadorNico"
    app.vm.network "private_network", ip: "192.168.10.100", virtualbox__intnet: "network1"
    app.vm.network "forwarded_port", guest: 80, host:8080
    # app.vm.provision "shell", path: "./Balanceador.sh"
  end

  #servidorNFSNico
  config.vm.define "servidorNFSNico" do |app|
    app.vm.hostname = "serverNFSNico"
    app.vm.network "private_network", ip: "192.168.10.200", virtualbox__intnet: "network1"
    app.vm.network "private_network", ip: "192.168.20.250", virtualbox__intnet: "network2"
    # app.vm.provision "shell", path: "./ServidorNFS.sh"
  end

  #servidorweb1Nico
  config.vm.define "servidorweb1Nico" do |app|
    app.vm.hostname = "servidorweb1Nico"
    app.vm.network "private_network", ip: "192.168.10.100", virtualbox__intnet: "network1"
    app.vm.network "private_network", ip: "192.168.20.100", virtualbox__intnet: "network2"
    # app.vm.provision "shell", path: "./servidorWeb1.sh"
  end

  #servidorweb2Nico
  config.vm.define "servidorweb2Nico" do |app|
    app.vm.hostname = "servidorweb2Nico"
    app.vm.network "private_network", ip: "192.168.10.101", virtualbox__intnet: "network1"
    app.vm.network "private_network", ip: "192.168.20.101", virtualbox__intnet: "network2"
    # app.vm.provision "shell", path: "./servidorWeb2.sh"  
end

  # Servidordatos1
  config.vm.define "ServidordatosNico" do |app|
    app.vm.hostname = "ServidordatosNico"
    app.vm.network "private_network", ip: "192.168.20.160", virtualbox__intnet: "network2"
    # app.vm.provision "shell", path: "./ServidorBD.sh"
  end

  config.ssh.insert_key = false
  config.ssh.forward_agent = false

end
