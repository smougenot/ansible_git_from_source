#!/usr/bin/env bash
#
# run like travis
#

# find the directory containing this code
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)


distro=centos
version=6
extra_args=

if [ $# -gt 1 ]; then
  distro="$1"
  version="$2"
else
  echo "usage $0 <distro (default $distro)> <version (default $version)>"
fi

# easy env mocking
if [ "$distro-$version" == "centos-7" ]; then
  extra_args="--privileged  -v /sys/fs/cgroup:/sys/fs/cgroup:ro "
fi

export distro version extra_args

echo "running with distro=$distro version=$version"
sh ${dir}/docker_prepare.sh && \
sh ${dir}/docker_check.sh
