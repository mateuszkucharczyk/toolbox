#!/bin/bash

source ../bin/strings.sh

function echoerr() { 
  echo "$@" 1>&2; 
}

function requires() {
  for the_command in "$@"
  do
    if ! type "${the_command}" >/dev/null 2>&1; then
      echoerr "[ERROR] I require '${the_command}' but it's not installed.  Aborting."; 
      exit 1;
    fi
  done
}

function get_local_dir() {
  # set to overwrite for test purposes
  if [[ -n "${LOCAL_DIR_OVERWRITE}" ]]; then
    echo "${LOCAL_DIR_OVERWRITE}"
  else 
    echo "/usr/local"
  fi
}

function get_install_dir() {
  local -r dir="$(get_local_dir)/apps"
  if [ ! -e "${dir}" ]; then
    mkdir "${dir}"
  fi
  
  echo "${dir}" 
}

function get_bin_dir() {
  local -r dir="$(get_local_dir)/bin"
  echo "$dir" 
}

function mkdirorexit() {
  mkdir "$@";
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] cannot 'mkdir ${$@}'. Aborting."; 
    exit 1
  fi
}

function mvorexit() {
  mv "$@";
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] cannot 'mv ${$@}'. Aborting."; 
    exit 1
  fi
}

function cdorexit() {
  cd "$@";
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] cannot 'cd ${$@}'. Aborting."; 
    exit 1
  fi
}


function remove_old_installation() {
  local -r dir="${1:?[ERROR] Old installation directory not provided}"
  if [ -d "${dir}" ]; then
    rm -r "${dir}"
  fi
}

function install_from_manager() {
  if [[ -n "${2}" ]]; then
    local -r repository="${2}"
    add-apt-repository -y "${repository}"
  fi
  
  apt-get update
  apt-get -y install "${1:?[ERROR] Package name not provided}"
}

function unpack_by_extension() {
  local -r src="${1:?[ERROR] source path not provided}";
  local -r dst="${2:-$(dirname ${1})}";

  if [[ "${src}" =~ \.zip$ ]]; then
    unzip -q "${src}" -d "${dst}"
  elif [[ "${src}" =~ \.tar\.gz$ ]]; then
    tar -xzf "${src}" -C "${dst}"
  else
    cp "${src}" "${dst}"
  fi
  echo "${dst}";
}

function wget_to_temp() {
  local -r url="${1:?[ERROR] url not provided}"
  local -r tmp=$(mktemp -d)
  
  wget --trust-server-names -P "${tmp}" "${url}"
  if [[ "$?" -ne 0 ]]; then
    exit 1
  fi
  local archname
  archname=$(ls ${tmp})
  echo "${tmp}/${archname:?[ERROR] Cannot determine archive name}"
}

function create_start_script() {
  local -r name="${1?:[ERROR] name not provided}"
  local -r executable="${2?:[ERROR] name not provided}"
  local -r dst="$(get_install_dir)/${name}"
 
  echo "cd ${dst}; ./${executable:?} \"\$@\"" > "$(get_bin_dir)/${name}"
  chmod 555 "$(get_bin_dir)/${name}"
}

function install_from_archive() {
  echo "lalal"
}

function grant_permissions_to_executables() {
  chmod -R 555 "$dst/"*.jar
  chmod -R 555 "$dst/"*.sh
}

function  download() {
  local -r url="${1:?[ERROR] url not provided}"
  local -r name="${2:?[ERROR] name not provided}"
  local -r executable="${3:?[ERROR] executable not provided}"
  
  if [[ "$@" == *--create-dir* ]]; then
    local -r install_dir="$(get_install_dir)/${name}"
    if ! mkdir "${install_dir}" ; then
      echo "[ERROR] Failed to create installation directory: ${install_dir}" >&2
      exit 1
    fi
  else
    local -r install_dir="$(get_install_dir)"
  fi
  
  # remove old installation if any
  remove_old_installation "$install_dir/$name"

  
  # download and install
  local archfile
  archfile=$(wget_to_temp "${url}")
  echo "<${archfile}>"
  if [[ "$?" -ne 0 ]]; then
    echo "Unable to downlad ${url}" >&2
    exit 1
  fi
  
  if ! unpack_by_extension "${archfile}" "${install_dir}" ; then
    echo "[ERROR] Failed to unpack <${archfile}> to <${install_dir}>" >&2
    exit 1
  fi

  #rename
  local src;
  local dst;
  src=$(ls -d $install_dir/* | grep -i $name)
  dst=$(dirname "${src}")/$name
  
  if [[ ! "${src}" -ef "${dst}" ]]; then
    if ! mv "${src}" "${dst}" ; then
      echo "[ERROR] Failed to rename <${src}> to <${dst}>" >&2
      exit 1
    fi  
  fi
  
  grant_permissions_to_executables
  create_start_script "${name}" "${executable}" 
}
