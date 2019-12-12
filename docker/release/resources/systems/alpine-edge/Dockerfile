FROM cassandra-php-driver-alpine-edge:base

RUN apk upgrade && apk add --no-cache \
    zip \
    unzip \
    jq \
    curl

WORKDIR /resources
COPY ./**.sh .
RUN ./zip_cassandra.sh

RUN chmod +x release.sh
CMD ["./release.sh", "./cassandra-php-driver.zip"]
