#!/usr/bin/env bash

# find the directory containing this code
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
_utilities="$dir/utils.sh"
if [ ! -r "$_utilities" ]; then
  echo "Tooling not found : $_utilities"
  exit 1
fi

source "$_utilities"

#
# testing role
#

# check code syntax
_info "Check code syntax"
ansible-playbook ${dir}/../test.yml --syntax-check
checkForError "Code syntax check failed"
_success "Check code syntax OK"

# test role
_info "Test ansible code"
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i "$inventoryFile" --user=provisionner --private-key=$sshPk ${dir}/../test.yml && \
  docker exec ansible_test git --version | grep -c '1.8.5.6'
checkForError "Error running test playbook"
_success "Test ansible code OK"

# test role idempotence
#_info "Test code idempotence"
#playbook_output=$(mktemp)
#ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i "$inventoryFile" --user=provisionner --private-key=$sshPk ${dir}/../test.yml | tee $playbook_output
#checkForError "Error running idempotence test playbook"
#cat ${playbook_output} | grep -q 'changed=0.*failed=0' \
#    && (_success  'Test code idempotence pass' && exit 0) \
#    || (_error 'Test code idempotence fail' && exit 1)
