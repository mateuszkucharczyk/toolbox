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
  pushd /vagrant/install
  ./configure-proxy "${http_proxy}"
  apt-get update && apt-get install -y cntlm
  ./configure-cntlm "${http_proxy}"
  ./configure-proxy "http://127.0.0.1:3128"
  start_cntlm
  ./configure-apt
  ./install-packet-installation-tools 
  #./install-packet-dev "vagrant"
  popd;
}

main "$@"