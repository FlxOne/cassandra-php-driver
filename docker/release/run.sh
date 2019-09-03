#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker_image='cassandra-php-driver:release'
docker_container='cassandra-php-driver'

# Create the container that has the Cassandra PHP driver build files
docker container rm "${docker_container}" > /dev/null 2>&1 && echo "Removed old ${docker_container} container."
docker run \
    -it \
    --name "${docker_container}" \
    "${docker_image}" \
