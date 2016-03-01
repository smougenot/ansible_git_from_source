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
# build docker image
#
distro=centos
version=6

_info "Generating ssh key"
rm -f "$sshPk" "$sshPk.pub"
ssh-keygen -q -t rsa -N "" -f "$sshPk" &&
  chmod 700 "$sshPk";
checkForError "Ssh key generation failed"
find . -name '*provisionner*' -exec ls -la {} \;

# Pull from image
_info "Get parent image"
docker pull ${distro}:${version}

# Build image
_info "Build image"
docker build --rm=true --file=Dockerfile.${distro}-${version} --tag=${distro}-${version}:ansible_test .
checkForError "Build image failed"
docker images
_success "Docker image ready"

#
# running container
#
_info "Running container"
docker rm -f ansible_test
docker run --detach --name ansible_test -P ${distro}-${version}:ansible_test /sbin/init
checkForError "Starting container failed"
_success "Docker image ready"
docker ps -a

# prepare inventory file
_info "Preparing inventory"
_containerPort="$(docker port ansible_test 22 | awk -F: '{print $2 }')"
echo -e "localhost:$_containerPort" > "$inventoryFile"
checkForError "Inventory failed"
cat "$inventoryFile"

_info "Ssh access check"
wait4ssh "$_containerPort"
checkForError "Ssh access failed"

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
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i "$inventoryFile" --user=provisionner --private-key=provisionner ${dir}/../test.yml
checkForError "Error running test playbook"
_success "Test ansible code OK"

# test role idempotence
_info "Test code idempotence"
playbook_output=$(ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i "$inventoryFile" --user=provisionner --private-key=provisionner ${dir}/../test.yml)
checkForError "Error running idempotence test playbook"
echo ${playbook_output} | grep -q 'changed=0.*failed=0' \
    && (_success  'Test code idempotence pass' && exit 0) \
    || (_error 'Test code idempotence fail' && exit 1)
