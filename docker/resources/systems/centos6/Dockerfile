FROM centos:centos6

# Profile setup
RUN echo $'\n\
alias ll="ls -al" \n\
' >> ~/.bash_profile

# Install CentOS yum repositories that are required
RUN rpm -Uvh \
    http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm \
    http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# Install PHP and C++ dependencies for building Cassandra extension
RUN yum install -y --enablerepo=remi-php73 \
    automake \
    cmake \
    gcc \
    gcc-c++ \
    git \
    libtool \
    openssl-devel \
    wget \
    gmp \
    gmp-devel \
    boost \
    pcre-devel \
    php-pear \
    php-devel

WORKDIR /tmp

# Install a newer autoconf (required for cassandra install)
RUN wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz \
&& tar xzf autoconf-2.69.tar.gz \
&& find . -maxdepth 1 -type f -name 'autoconf*.tar.gz' -delete \
&& { find . -maxdepth 1 -type d -name 'autoconf*'; echo 'autoconf'; } | xargs -n2 mv \
&& pushd autoconf \
&& ./configure \
&& make install \
&& popd \
|| { echo "Failed installing autoconf library." ; exit 1 ; }

# Build libuv (Extract tar, delete tar, rename dir to 'libuv' and install)
RUN wget http://dist.libuv.org/dist/v1.8.0/libuv-v1.8.0.tar.gz \
&& tar xzf libuv-v1.8.0.tar.gz \
&& find . -maxdepth 1 -type f -name 'libuv*.tar.gz' -delete \
&& { find . -maxdepth 1 -type d -name '*libuv*' | tail -1; echo 'libuv'; } | xargs -n2 mv \
&& pushd libuv \
&& ./autogen.sh \
&& ./configure \
&& make install \
&& popd \
|| { echo "Failed installing libuv library." ; exit 2 ; }

# Get Cassandra source code and build the PHP extension (removing '-dev' from version tag)
RUN git clone https://github.com/datastax/php-driver.git \
&& pushd php-driver \
&& git submodule update --init \
&& pushd ext \
&& sed -i 's/-dev//g' package.xml \
|| { echo "Failed cloning datastax Cassandra PHP driver git repository from GitHub." ; exit 3 ; }

# Build C++ Cassandra (required because it's wrapped by PHP extension)
WORKDIR /tmp/php-driver/lib/cpp-driver
RUN cmake . \
&& make install \
&& cp /usr/local/lib64/libcassandra.so /usr/lib64/libcassandra.so \
&& pushd "/usr/lib64/" \
&& ln -s "libcassandra.so" "libcassandra.so.2" \
|| { echo "Failed installing Cassandra C++ library." ; exit 4 ; }

# Build PHP Cassandra extension
WORKDIR /tmp/php-driver/ext
RUN phpize
RUN ./configure --with-cassandra=/tmp/php-driver/lib/cpp-driver --with-libdir=lib

# Install Cassandra extension into PHP (these steps are not required but useful for testing)
RUN pecl install /tmp/php-driver/ext/package.xml
RUN echo 'extension=cassandra.so' >> $(php -i | awk '/^Loaded Configuration File/{print $NF}')

CMD ["/bin/bash"]
