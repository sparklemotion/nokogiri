# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Box = Struct.new(:shortname, :name, :provision)

# Every Vagrant development environment requires a box. You can search for
# boxes at https://vagrantcloud.com/search.
boxen = []
boxen << Box.new("openbsd", "generic/openbsd6", <<~EOF)
  # install rvm
  pkg_add gnupg-2.2.12p0
  gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable
  source /etc/profile.d/rvm.sh
  usermod -G rvm vagrant

  # install ruby and build-essentials
  rvm install ruby-2.7
EOF
boxen << Box.new("bionic32", "mkorenkov/ubuntu-bionic32", <<~EOF)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y apt-utils
  apt-get install -y libxslt-dev libxml2-dev pkg-config
  apt-get install -y ruby ruby-dev bundler git
EOF
boxen << Box.new("freebsd", "freebsd/FreeBSD-13.0-CURRENT", <<~EOF)
  pkg install rbenv ruby-build
EOF

Vagrant.configure("2") do |config|
  boxen.each do |box|
    config.vm.define(box.shortname) do |config|
      config.vm.box = box.name

      # Share an additional folder to the guest VM. The first argument is
      # the path on the host to the actual folder. The second argument is
      # the path on the guest to mount the folder. And the optional third
      # argument is a set of non-required options.
      # config.vm.synced_folder "../data", "/vagrant_data"

      config.vm.provider("virtualbox") do |vb|
        vb.customize(["modifyvm", :id, "--cpus", 2])
        vb.customize(["modifyvm", :id, "--memory", 1024])
      end

      config.vm.synced_folder(".", "/nokogiri")

      if box.provision
        config.vm.provision("shell", inline: box.provision)
      end
    end
  end

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
