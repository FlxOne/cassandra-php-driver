FROM alpine:edge

RUN apk upgrade

# Install tools supporting build process
RUN apk update && apk add --no-cache \
    wget \
    git \
    bash \
    zip

# Use BASH shell for the rest of the Docker commands
SHELL ["/bin/bash", "-c"]

# Install C++ dependencies for building Cassandra extension
RUN apk add --no-cache \
    build-base \
    automake \
    libtool \
    cmake \
    openssl-dev \
    gmp \
    gmp-dev \
    autoconf

# Install PHP to test Cassandra installation
RUN apk add --no-cache \
    php7 \
    php7-dev \
    php7-pear

# Build libuv (Extract and delete tar, rename dir to 'libuv' and install)
RUN wget http://dist.libuv.org/dist/v1.13.1/libuv-v1.13.1.tar.gz \
&& tar xzf libuv-v1.13.1.tar.gz \
&& find . -maxdepth 1 -type f -name 'libuv*.tar.gz' -delete \
&& { find . -maxdepth 1 -type d -name '*libuv*' | tail -1; echo 'libuv'; } | xargs -n2 mv \
&& pushd libuv \
&& ./autogen.sh \
&& ./configure \
&& make install \
&& popd \
|| { echo "Failed installing libuv library." ; exit 2 ; }

# Get Cassandra source code and build the PHP extension (removing '-dev' from version tag)
WORKDIR /tmp
RUN git clone --recurse-submodules https://github.com/datastax/php-driver.git \
&& pushd php-driver/ext \
&& sed -i 's/-dev//g' package.xml \
|| { echo "Failed cloning datastax Cassandra PHP driver git repository from GitHub." ; exit 3 ; }

# Build C++ Cassandra (required because it's wrapped by PHP extension)
# Also remove warnings-as-errors flag for cmake
WORKDIR /tmp/php-driver/lib/cpp-driver
RUN find . -type f -iname '*.cmake' -exec sed -i "s/ -Werror//" {} \; \
&& cmake . \
&& make install \
&& cp libcassandra.so /usr/lib/libcassandra.so \
&& pushd "/usr/lib/" \
&& ln -s "libcassandra.so" "libcassandra.so.2" \
|| { echo "Failed installing Cassandra C++ library." ; exit 4 ; }

# Build PHP Cassandra extension
WORKDIR /tmp/php-driver/ext
RUN phpize
RUN ./configure --with-cassandra=/tmp/php-driver/lib/cpp-driver --with-libdir=lib

# Install Cassandra extension into PHP (these steps are not required but validate the installation of Cassandra)
RUN pecl install /tmp/php-driver/ext/package.xml \
&& echo 'extension=cassandra.so' >> $(php -i | awk '/^Loaded Configuration File/{print $NF}') \
&& php -m | grep -Fxq "cassandra" \
|| { echo "Cassandra module was not loaded by PHP. Installation failed." ; exit 5 ; }

# Install zip/install scripts
COPY /resources/systems/alpine-edge/resources/ /resources

WORKDIR /resources
CMD ["/bin/bash"]
