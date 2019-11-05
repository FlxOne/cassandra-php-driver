#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${dir}/resources/system_select.sh" "${@}" "--store" "system"

echo "Now building Cassandra PHP Driver for $(basename ${system}).."
docker build \
    --tag="cassandra-php-driver-$(basename "${system}"):base" \
    -f "${system}/Dockerfile" \
    "${dir}/.."
