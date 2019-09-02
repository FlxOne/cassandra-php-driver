FROM cassandra-php-driver:base

RUN yum install -y \
    zip \
    unzip \
    jq

WORKDIR /resources
COPY ./resources .

RUN /resources/zip_cassandra.sh

ENTRYPOINT ["bash"]
