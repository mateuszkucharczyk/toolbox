#!/bin/bash

function start_cntlm() {
  service cntlm start;
  local running="";
  while [ -z "${running}" ]; do
    sleep 1;
    running=$(service cntlm status | grep 'active (running)');
  done
}

function main() {
  local -r http_proxy="${1:?[ERROR] http_proxy not provided (http://<domain>\<username>:<password>@<proxy>:<port>)}";
  local -r domain="${2:?[ERROR] domain not provided}";
  local -r user="vagrant";
  
  pushd /vagrant/install
  ./configure-proxy "${http_proxy}"
  apt-get update && apt-get install -y cntlm
  ./configure-cntlm "${http_proxy}" "${domain}"
  ./configure-proxy "http://127.0.0.1:3128"
  start_cntlm
  ./configure-apt
  
  # fixme: applied to root user instead vagrant user
  #./configure-xfce 
  
  source /etc/profile.d/proxy.sh;
  ./install-packet-installation-tools 
  ./install-git
  ../setupstream "https://github.com/mateuszkucharczyk/toolbox.git" "/vagrant"
  #./install-packet-dev "${user}"
  popd;
}

main "$@" > /vagrant/stdout
