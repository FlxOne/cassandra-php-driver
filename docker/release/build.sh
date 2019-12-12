#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker_image='cassandra-php-driver'

# Ask user for system to build
source "${dir}/../resources/system_select.sh" \
    "--store" "releaseSystemDir" \
    "--resources" "${dir}/resources" \
    || { echo "Failed getting systems from '${dir}/resources'." ; exit 1 ; }

[[ -d "${releaseSystemDir}" ]] || { echo "Unsupported system returned by build script. No base build for: '${releaseSystemDir}'" ; exit 1 ; }
systemName=$(basename "${releaseSystemDir}")

"../build.sh" "--system" "${systemName}" || { echo "Failed building base image for system '${systemName}'" ; exit 1 ; }
docker build \
    --tag="${docker_image}:release" \
    -f "${releaseSystemDir}/Dockerfile" \
    "${dir}"
