#!/usr/bin/env bash
# Installs Cassandra PHP extension into a CentOS container from the zipped files created by the zip_cassandra.sh script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

skip_ini=false
skip_verify=false
for arg in "${@}"; do
    case "${arg}" in
        "--skip-ini")
            skip_ini=true
        ;;
        "--skip-verify")
            skip_verify=true
        ;;
    esac
done

function filesExist() {
    for file in "${@}"; do
        [[ -f "${file}" ]] || { echo "File ${file} does not exist." ; return 1 ; }
    done
    return 0
}

function installLibrary() {
    local library="${1}"
    filesExist "${library}" || return 1

    # Remove old installations and move library to system lib directory
    pushd /usr/lib \
    && find . \( -type f -o -type l \) -name "${library}*" -delete \
    && mv "${library}" "./" \
    || { echo "Failed moving library to System library directory." ; return 1 ; }

    # Skips first arg.
    # Create symbolic links to other version so that PHP will look for the right file..
    for ext in "${@:2}"; do
        ln -s "$(basename ${library})" "$(basename ${library})${ext}"
    done
}

php_ini_file=$(php -i | awk '/^Loaded Configuration File/{print $NF}')
[[ -f "${php_ini_file}" ]] || { echo "PHP ini file not found." ; exit 4 ; }
php_extension_dir=$(php -i | awk '/^extension_dir/{print $NF}')
[[ -d "${php_extension_dir}" ]] || { echo "Unable to retrieve extension directory from PHP installation." ; exit 3 ; }

file_libuv=$(readlink -f "${dir}/libuv.so")
file_cpp_cassandra=$(readlink -f "${dir}/libcassandra.so")
file_cassandra_php_ext=$(readlink -f "${dir}/cassandra.so")
file_libgmp=$(readlink -f "${dir}/libgmp.so")

# Validate all files exist before starting installation
filesExist \
    "${file_libuv}" \
    "${file_cpp_cassandra}" \
    "${file_cassandra_php_ext}" \
    "${file_libgmp}" \
    || { echo "One or more required installation files are missing." ; exit 2 ; }

installLibrary "${file_libgmp}" ".10"
installLibrary "${file_cpp_cassandra}" ".2"
installLibrary "${file_libuv}" ".1" ".1.0.0"

# Install PHP cassandra extension
cd "${php_extension_dir}"
find . -type f -name 'cassandra.so' -delete
mv "${file_cassandra_php_ext}" "./"

# Add cassandra to php.ini if needed
if [[ "${skip_ini}" == "false" ]]; then
    if [[ $(cat "${php_ini_file}" | grep '^extension=cassandra.so') == "" ]]; then
        echo "extension=cassandra.so" >> "${php_ini_file}"
    fi
fi

# Verify PHP has Cassandra module
if [[ "${skip_verify}" == "false" ]]; then
    [[ $(php -m | grep '^cassandra') != "" ]] || { echo "PHP does not list Cassandra as a loaded extension. Installation failed." ; exit 5 ; }
fi

echo "Cassandra extension for PHP is installed"
