#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker_image='cassandra-php-driver:release'
docker_container='cassandra-php-driver'

"${dir}/../build.sh" "${@}" || { echo "Failed to build base image." ; exit 1 ; }

docker build \
    "${@}" \
    --tag="${docker_image}" \
    -f "${dir}/Dockerfile" \
     .
