#!/bin/bash

function main() {
  local -r http_proxy="${1:?[ERROR] http_proxy not provided (http://<domain>\<username>:<password>@<proxy>:<port>)}";
  local -r domain="${2:?[ERROR] domain not provided}";
  local -r user="vagrant";
  
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

main "$@" > /vagrant/stdout-dev
