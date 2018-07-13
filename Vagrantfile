# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'
opts = GetoptLong.new(
        [ '--no-gui', GetoptLong::NO_ARGUMENT ]
)

gui = true
opts.each do |opt|
 case opt
   when '--no-gui'
    gui = false
 end
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  #disable vagrant-proxyconf plugin
  #config.proxy.enabled = false
  
  config.vm.box = "bstoots/xubuntu-16.04-desktop-amd64"
  config.vm.hostname = "xubuntu"

  config.vm.provider "virtualbox" do |vb|
  vb.gui = gui
  
  # Customize the resources on the VM:
  vb.memory = 10240
  vb.cpus = 2
  vb.customize ["modifyvm", :id, "--vram", "64"]
  # disable 2D acceleration - it works only for Windows guest
  vb.customize ["modifyvm", :id, "--accelerate2dvideo", "off"]
  # disable 3D acceleration - IntellJ Toolbox does not display when turned on
  vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
  
  vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
  
  # disable usb
  vb.customize ["modifyvm", :id, "--usb", "off"]
  vb.customize ["modifyvm", :id, "--usbehci", "off"]
  vb.customize ["modifyvm", :id, "--usbxhci", "off"]
  
  # disable remote display
  vb.customize ["modifyvm", :id, "--vrde", "off"]
  end

  # escape '\'
  # http://<username>:<password>@<proxy>:<port>
  config.vm.provision "shell", path: "provision.sh", args: ["#{ENV['http_proxy']}", "#{ENV['USERDOMAIN']}"]
  
  
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

end
