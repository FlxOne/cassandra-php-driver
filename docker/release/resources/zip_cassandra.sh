#!/bin/bash
# Finds the Cassandra dependencies and bundles the files together into a zip.

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

zipfiles() {
    for arg in "${@:2}"; do
        [[ -f "${arg}" ]] || { echo "File ${arg} does not exist." ; return 1 ; }
    done

    zip -9 -j "$1" "${@:2}"
    return $?
}

# Register libraries in ldconfig listing
ldconfig
ldconfig /usr/local/lib

# Installation script
file_install=$(readlink -f "/resources/install_cassandra.sh")
[[ -f "${file_install}" ]] || { echo "Error: Could not find Cassandra installation script." ; exit 6 ; }

# Libuv library file
file_libuv=$(ldconfig -p | awk '/libuv*.so$/{print $NF}')
[[ -f "${file_libuv}" ]] || { echo "Error: Could not find Libuv library." ; exit 5 ; }

# Cassandra C++ library file
file_libcassandra=$(ldconfig -p | awk '/libcassandra/{print $NF}')
[[ -f "${file_libcassandra}" ]] || { echo "Error: Could not find C++ Cassandra library." ; exit 3 ; }

# Cassandra PHP extension file
php_extensions_dir=$(php -i | awk '/extension_dir/{print $NF}')
file_cassandra_php_ext="${php_extensions_dir}/cassandra.so"
[[ -d "${php_extensions_dir}" ]] || { echo "Error: PHP info has an invalid modules directory. Either PHP command failed or directory does not exist." ; exit 1 ; }
[[ -f "${file_cassandra_php_ext}" ]] || { echo "Error: Cassandra is not found in PHP extensions listing." ; exit 2 ; }

# Zip build files of Cassandra
pushd /resources \
&& zipfiles 'cassandra-php-driver.zip' "${file_install}" "${file_cassandra_php_ext}" "${file_libcassandra}" "${file_libuv}" \
&& popd \
|| { echo "Failed to zip required Cassandra PHP plugin files." ; exit 4 ; }
