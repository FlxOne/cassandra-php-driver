FROM centos:centos8

# Profile setup
RUN echo $'\n\
alias ll="ls -al" \n\
' >> ~/.bashrc

# Install CentOS yum repositories that are required
RUN dnf install -y -q \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# Install tools supporting build process
RUN dnf install -y \
    wget \
    git

# Install C++ dependencies for building Cassandra extension
RUN dnf install -y \
    automake \
    binutils \
    bison \
    flex \
    gcc \
    gcc-c++ \
    gdb \
    glibc-devel \
    libtool \
    make \
    pkgconf \
    pkgconf-m4 \
    pkgconf-pkg-config \
    redhat-rpm-config \
    rpm-build \
    rpm-sign \
    strace \
    cmake \
    openssl-devel

# Install PHP build tools required for configuration of Cassandra for PHP extension
RUN dnf module install -y -q php:remi-7.3
# TODO: Fix install error for repo packacges and remove link to static files
RUN dnf -y install https://rpmfind.net/linux/fedora/linux/releases/29/Everything/x86_64/os/Packages/l/libedit-3.1-24.20170329cvs.fc29.x86_64.rpm
RUN dnf -y install https://rpmfind.net/linux/fedora/linux/releases/29/Everything/x86_64/os/Packages/l/libedit-devel-3.1-24.20170329cvs.fc29.x86_64.rpm
RUN dnf install -y \
    gmp-devel \
    pcre-devel \
    php-pear \
    php-devel

WORKDIR /tmp

# Install specific autoconf (required for cassandra install)
RUN wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz \
&& tar xzf autoconf-2.69.tar.gz \
&& find . -maxdepth 1 -type f -name 'autoconf*.tar.gz' -delete \
&& { find . -maxdepth 1 -type d -name 'autoconf*'; echo 'autoconf'; } | xargs -n2 mv \
&& pushd autoconf \
&& ./configure \
&& make install \
&& popd \
|| { echo "Failed installing autoconf library." ; exit 1 ; }

# Build libuv (Extract and delete tar, rename dir to 'libuv' and install)
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
RUN git clone --recurse-submodules https://github.com/datastax/php-driver.git \
&& pushd php-driver/ext \
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

# Install Cassandra extension into PHP (these steps are not required validate the installation of Cassandra)
RUN pecl install /tmp/php-driver/ext/package.xml
RUN echo 'extension=cassandra.so' >> $(php -i | awk '/^Loaded Configuration File/{print $NF}')

CMD ["/bin/bash"]
