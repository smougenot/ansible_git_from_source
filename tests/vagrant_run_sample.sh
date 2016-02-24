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

# start vagrant VM
_info "Starting Vagrant VM"
cd ${dir}
vagrant up
checkForError "Error starting VM"


# check code syntax
_info "Check code syntax"
ansible-playbook ${dir}/../test.yml --syntax-check
checkForError "Code syntax check failed"
_success "Check code syntax OK"

# test role
_info "Test ansible code"
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ${dir}/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory ${dir}/../test.yml
checkForError "Error running test playbook"
_success "Test ansible code OK"

# test role idempotence
_info "Test code idempotence"
playbook_output=$(ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ${dir}/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory ${dir}/../test.yml)
checkForError "Error running idempotence test playbook"
echo ${playbook_output} | grep -q 'changed=0.*failed=0' \
    && (_success  'Test code idempotence pass' && exit 0) \
    || (_error 'Test code idempotence fail' && exit 1)
