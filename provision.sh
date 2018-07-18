#!/bin/bash

function main() { 
  printenv | grep proxy
  
  pushd /vagrant/install
  ./configure-apt
  
  
  # fixme: applied to root user instead vagrant user
  #./configure-xfce 
  
  ./install-packet-installation-tools 
  ./install-git
  ../setupstream "https://github.com/mateuszkucharczyk/toolbox.git" "/vagrant"
  #./install-packet-dev "${user}"
  popd;
}

main "$@" > /vagrant/stdout-dev.log
