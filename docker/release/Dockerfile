FROM cassandra-php-driver:base

RUN yum install -y \
    zip \
    unzip \
    jq

WORKDIR /resources
COPY ./resources .

RUN /resources/zip_cassandra.sh

CMD ["bash", "/resources/release.sh", "/resources/cassandra-php-driver.zip"]
