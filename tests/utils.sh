#!/usr/bin/env bash

# find the directory containing this code
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)


#
# Utilities
#

_NC='\e[0m'
_RED='\e[31m'
_CYAN='\e[36m'
_WHITE='\e[37m'
_GREEN='\e[42m'
_debug_on=1

# Display debug message
# $1 => message
function _debug {
  if [ ! -z "$_debug_on" ]; then
    echo -e "${_WHITE}$*${_NC}"
  fi
}

# Display info message
# $1 => message
function _info {
  echo -e "${_CYAN}$*${_NC}"
}

# Display error message
# $1 => message
function _error {
  >&2 echo -e "${_RED}$*${_NC}"
}

# Display success message
# $1 => message
function _success {
  >&2 echo -e "${_GREEN}$*${_NC}"
}

#
# $1 le message d'erreur
#
function checkForError {
  local _ret=$?
  if [ ! ${_ret} -eq 0 ]; then
      _error "$1"
      exit 1
  fi
}

# check ssh
# $1 ssh port
function sshCheck {
  local port="$1"
  _debug "Ssh access check"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${dir}/provisionner -p "$port" provisionner@localhost <<EOFSSH
  echo "It's alive"
EOFSSH
  local ret=$?
  _debug "ssh returned $ret"
  return $ret
}

# check ssh
# $1 ssh port
function wait4ssh {
  local port="$1"
  local c=10
  local _sleepTime=1
  sshCheck "$port"
  local ret=$?
  while [ ${c} -gt 0 ] && [ ! ${ret} -eq 0 ]; do
    _debug "waiting for ssh access : $c"
    (( c-- ))
    sleep ${_sleepTime}
    # check again
    sshCheck "$port"
    ret=$?
  done
  if [ ! ${ret} -eq 0 ]; then
    _error "No ssh access"
    return 1
  fi
  return 0
}
