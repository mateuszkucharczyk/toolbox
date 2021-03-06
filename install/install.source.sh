#!/bin/bash

source ../bin/strings.sh

#quiet pushd/popd
#https://stackoverflow.com/a/25288289
function pushd () {
  command pushd "$@" > /dev/null;
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] pushd" "$@";
    exit 1
  fi
}

function popd () {
  command popd "$@" > /dev/null;
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] popd" "$@";
    exit 1
  fi
}

function echoerr() { 
  echo "$@" 1>&2; 
  echo "  in function: ${FUNCNAME[1]}" 1>&2;
  echo "    at: $(caller 1)" 1>&2;
  echo "      stacktrace: ${FUNCNAME[*]:1}" 1>&2;
}

#https://stackoverflow.com/a/5300429
function final_url() {
  local -r url="${1:?[ERROR] url not provided}"
  curl -Ls -o /dev/null -w %{url_effective} "${url}";
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] final_url";
    exit 1
  fi
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
    echoerr "[ERROR] cannot 'mkdir $@'. Aborting."; 
    exit 1
  fi
}

function mvorexit() {
  mv "$@";
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] cannot 'mv $@'. Aborting."; 
    exit 1
  fi
}

function cdorexit() {
  cd "$@";
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] cannot 'cd $@'. Aborting."; 
    exit 1
  fi
}


function remove_old_installation() {
  local -r dir="${1:?[ERROR] Old installation directory not provided}"
  if [ -d "${dir}" ]; then
    rm -r "${dir}"
  fi
}

function apt-get() {
   DEBIAN_FRONTEND=noninteractive command apt-get "$@"
}

function apt() {
  DEBIAN_FRONTEND=noninteractive command apt "$@"
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
  
  pushd "${tmp}";
  # https://stackoverflow.com/a/7451779
  curl -Ls -O -J "${url}";
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] cannot download >${url}<";
    exit 1
  fi
  local archname=$(ls ${tmp})
  echo "${tmp}/${archname:?[ERROR] Cannot determine archive name}"
  popd;
}

function create_start_script() {
  local -r name="${1?:[ERROR] name not provided}"
  local -r executable="${2?:[ERROR] name not provided}"
  local -r dst="$(get_install_dir)/${name}"
 
  echo "cd ${dst}; ./${executable:?} \"\$@\"" > "$(get_bin_dir)/${name}"
  chmod 555 "$(get_bin_dir)/${name}"
}

function grant_permissions_to_executables() {
  local -r dst="${1?:[ERROR] dst not provided}"
  chmod -R -f 555 "${dst}/"*.jar
  chmod -R -f 555 "${dst}/"*.sh
}

function  download() {
  local -r url="${1:?[ERROR] url not provided}"
  local -r name="${2:?[ERROR] name not provided}"
  local -r executable="${3:?[ERROR] executable not provided}"
  
  local -r install_dir="$(get_install_dir)/${name}";
  
  # remove old installation if any
  remove_old_installation "${install_dir}"

  
  # download and install
  local archfile
  archfile=$(wget_to_temp "${url}")
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] Unable to downlad ${url}";
    exit 1
  fi
  
  local -r tmpdir="${archfile%/*}";
  if [[ "$@" == *--create-dir* ]]; then
    local -r unpackdir="${tmpdir}/unpack_here/${name}";
  else
    local -r unpackdir="${tmpdir}/unpack_here";
  fi
  mkdirorexit -p "${unpackdir}";

  if ! unpack_by_extension "${archfile}" "${unpackdir}" ; then
    echoerr "[ERROR] Failed to unpack '${archfile}' to '${unpackdir}'";
    exit 1;
  fi
  
  # move
  local -r appdir=$(ls ${tmpdir}/unpack_here)
  local -r apppath="${tmpdir}/unpack_here/${appdir}"
  mvorexit "${apppath}" "${install_dir}/";

  grant_permissions_to_executables "${install_dir}/";
  chmod 555 "${install_dir}/${executable}";
  create_start_script "${name}" "${executable}";
}

function find_by_xpath() {
  local -r url="${1:?[ERROR] url not provided}";
  local -r xpath="${2:?[ERROR] xpath not provided}";
  local href;
  href=$(wget -q -O - "${url}" | xmllint --html --xpath "${xpath}" - 2>/dev/null);
#|| -z "$href"
  if [[ "$?" -ne 0 ]]; then
    echoerr "[ERROR] cannot find href by xpath '${xpath}' on '${url}'"; 
    exit 1;
  fi
  echo "${href}";
}

function download_from_maven_repository() {
  local -r groupId="${1:?[ERROR] groupId not provided}";
  local -r artifactId="${2:?[ERROR] artifactId not provided}";
  local -r dst="${3:?[ERROR] destination directory not provided}";
  
  local -r latest_url=$(final_url "https://mvnrepository.com/artifact/${groupId}/${artifactId}/latest");
  local -r versionId="${latest_url##*/}";

  local -r filename="${artifactId}-${versionId}.jar";
  local -r download_url='http://central.maven.org/maven2/'$(echo "${groupId}" | tr '.' '/')"/${artifactId}/${versionId}/${filename}"

  local -r filepath="${dst}/${filename}";
  wget -q -O "${filepath}" "${download_url}";
  chmod 444 "${filepath}";
}

function install_autocompletion() {
  #https://serverfault.com/a/506707
  #https://github.com/scop/bash-completion/blob/master/README.md
  local -r url="${1:? url not provided}";
  local -r pathname="$(pkg-config --variable=completionsdir bash-completion)/${url##*/}";
  curl -L "${url}" -o "${pathname}";
  chmod 555 "${pathname}"
}
