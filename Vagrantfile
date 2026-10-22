Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 512
    vb.cpus = 1
  end

  config.vm.define "primario" do |p|
    p.vm.hostname = "debian"
    p.vm.network "private_network", ip: "192.168.56.10"
    p.vm.provision "shell", path: "config/primario.sh"
    p.vm.provision "shell", path: "config/test.sh"
  end

  config.vm.define "secundario" do |s|
    s.vm.hostname = "debian2"
    s.vm.network "private_network", ip: "192.168.56.11"
    s.vm.provision "shell", path: "config/secundario.sh"
  end
end
