FROM cassandra-php-driver:base

RUN yum install -y \
    zip \
    unzip \
    jq

WORKDIR /resources
COPY ./resources .

RUN /resources/zip_cassandra.sh

RUN chmod +x /resources/release.sh
CMD ["/resources/release.sh", "/resources/cassandra-php-driver.zip"]
