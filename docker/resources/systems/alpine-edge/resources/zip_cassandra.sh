#!/bin/bash
# Finds the Cassandra dependencies and bundles the files together into a zip.

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
libdir="/usr/lib"

zipfiles() {
    for arg in "${@:2}"; do
        [[ -f "${arg}" ]] || { echo "File $(pwd)/${arg} does not exist." ; return 1 ; }
    done

    zip -9 -j "$1" "${@:2}"
}

copyLibrary() {
    [[ "${libdir}" != "" && -d "${libdir}" ]] || { echo "System library directory at '${libdir}' does not exist." ; return 1 ; }

    local libname="${1}"
    local toDir="${2}"

    local lib_file_found=$(find "${libdir}" -type f -iname "${libname}*" | tail -n1)
    [[ -f "${lib_file_found}" ]] || { echo "Could not find library '${libname}' to copy in '${libdir}'." ; return 2 ; }

    cp "$(readlink -f "${lib_file_found}")" "${toDir}/${libname}"
}

# Register libraries in ldconfig listing
ldconfig
ldconfig /usr/local/lib

# Installation script
file_install=$(readlink -f "/resources/install_cassandra.sh")
[[ -f "${file_install}" ]] || { echo "Error: Could not find Cassandra installation script." ; exit 6 ; }

libs_to_install=('libuv.so' 'libcassandra.so' 'libgmp.so')
for lib in "${libs_to_install[@]}"; do
    copyLibrary "${lib}" "/resources" || { echo "Failed to copy installed library '${lib}' from system files to '/resources'." ; exit 1 ; }
done

# Cassandra PHP extension file
php_extensions_dir=$(php -i | awk '/extension_dir/{print $NF}')
file_cassandra_php_ext="${php_extensions_dir}/cassandra.so"
[[ -d "${php_extensions_dir}" ]] || { echo "Error: PHP info has an invalid modules directory. Either PHP command failed or directory does not exist." ; exit 1 ; }
[[ -f "${file_cassandra_php_ext}" ]] || { echo "Error: Cassandra is not found in PHP extensions listing." ; exit 2 ; }

# Zip build files of Cassandra
pushd /resources \
&& zipfiles 'cassandra-php-driver.zip' "${file_install}" "${file_cassandra_php_ext}" "libuv.so" "libcassandra.so" "libgmp.so" \
&& popd \
|| { echo "Failed to zip required Cassandra PHP plugin files." ; exit 4 ; }
