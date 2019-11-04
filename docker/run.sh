#!/bin/bash

docker run \
    --rm \
    -it \
    --name cassandra-php-driver \
    cassandra-php-driver:base \
    /bin/bash
