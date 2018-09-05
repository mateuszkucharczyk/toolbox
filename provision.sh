#!/bin/bash

function main() {   
  local -r user='vagrant';
  
  pushd /vagrant/install
  ./configure-apt

  ./install-xfce
  ./install-guest-additions "${user}"
  ./install-packet-installation-tools 
  ./install-git
  ../setupstream "https://github.com/mateuszkucharczyk/toolbox.git" "/vagrant"
  ./install-terminal "${user}"
  # ./install-packet-dev "${user}"
  popd;
}

main "$@" > /vagrant/stdout-dev.log
