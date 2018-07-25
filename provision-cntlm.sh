#!/bin/bash

function main() {
  local -r proxy="${1:?[ERROR] proxy not provided (http://<username>:<password>@<proxy>:<port>)}";
  local -r domain="${2:?[ERROR] domain not provided}";
  local -r noproxy="${3:-}";

  local -r user="vagrant";
  
  cd '/vagrant/install' && \
  ./configure-proxy "${proxy}" && \
  ./install-cntlm "${proxy}" "${domain}" "${noproxy}" && \
  ./configure-proxy 'http://127.0.0.1:3128'
}

main "$@";
