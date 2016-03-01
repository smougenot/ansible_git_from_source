#!/usr/bin/env bash

# find the directory containing this code
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)


distro=centos
version=6
export distro version

sh $dir/docker_prepare.sh && \
sh $dir/docker_check.sh
