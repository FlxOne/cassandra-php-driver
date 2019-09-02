#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build \
    "${@}" \
    --tag=cassandra-php-driver:base \
    -f "${dir}/Dockerfile" \
     "${dir}/.."
