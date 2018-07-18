#!/bin/bash

# https://blogs.oracle.com/linux/the-top-10-tricks-of-perl-one-liners-v2
# https://perldoc.perl.org/perlop.html#Range%20Operators

function prepend_first_matching_line() {
  replace_first_matching_line '(?P<matching_line>'"${1}"')' "${2}"'\n$+{matching_line}' "${3}"
}

function append_first_matching_line() {
  replace_first_matching_line '(?P<matching_line>'"${1}"')' '$+{matching_line}\n'"${2}" "${3}"
}

function replace_first_matching_line() {
  local -r replaced_line="${1:?[ERROR] replaced line regex not provided}";
  local -r replacement_line="${2:?[ERROR] replacement line not provided}";
  local -r file="${3:?[ERROR] file not provided}";
  perl -i -lp -e 's/^'"${replaced_line}"'$/'"${replacement_line}"'/ .. true' "${file}"
}

function replace_all_matching_lines() {
  local -r replaced_line="${1:?[ERROR] replaced line regex not provided}";
  local -r replacement_line="${2:?[ERROR] replacement line not provided}";
  local -r file="${3:?[ERROR] file not provided}";
  perl -i -lp -e 's/^'"${replaced_line}"'$/'"${replacement_line}"'/' "${file}"
}