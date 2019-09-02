#!/usr/bin/env bash
# Installs Cassandra PHP extension into a CentOS container from the zipped files created by the zip_cassandra.sh script

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

filesExist() {
    for arg in "${@}"; do
        [[ -f "${arg}" ]] || { echo "File ${arg} does not exist." ; return 1 ; }
    done
    return 0
}

php_ini_file=$(php -i | awk '/^Loaded Configuration File/{print $NF}')
[[ -f "${php_ini_file}" ]] || { echo "PHP ini file not found." ; exit 4 ; }
php_extension_dir=$(php -i | awk '/^extension_dir/{print $NF}')
[[ -d "${php_extension_dir}" ]] || { echo "Unable to retrieve extension directory from PHP installation." ; exit 3 ; }

file_libuv=$(readlink -f "./libuv.so")
file_cpp_cassandra=$(readlink -f "./libcassandra.so.2")
file_cassandra_php_ext=$(readlink -f "./cassandra.so")

# Validate all files exist before starting installation
filesExist \
    "${file_libuv}" \
    "${file_cpp_cassandra}" \
    "${file_cassandra_php_ext}" \
    || { echo "One or more required installation files are missing." ; exit 2 ; }

# Delete old cassandra libraries and replace with new one (install as 'cassandra.so.2')
cd /usr/lib64
find . \( -type f -o -type l \) -name 'libcassandra.so*' -delete
mv "${file_cpp_cassandra}" "./"
ln -s "${file_cpp_cassandra}" "$(basename \"${file_cpp_cassandra}.2\")"


# Install Libuv library (removes previous libuv installation and symlinks)
cd "/usr/local/lib"
find . \( -type f -o -type l \) -name 'libuv.so*' -delete
mv "${file_libuv}" "./"
ln -s "libuv.so" "libuv.so.1"
ln -s "libuv.so.1" "libuv.so.1.0.0"

# Install PHP cassandra extension
cd "${php_extension_dir}"
find . -type f -name 'cassandra.so' -delete
mv "${file_cassandra_php_ext}" "./"

# Add cassandra to php.ini if needed
if [[ ${skip_ini} == false ]]; then
    if [[ $(cat "${php_ini_file}" | grep '^extension=cassandra.so') == "" ]]; then
        echo "extension=cassandra.so" >> "${php_ini_file}"
    fi
fi

# Verify PHP has Cassandra module
if [[ ${skip_verify} == false ]]; then
    [[ $(php -m | grep '^cassandra') != "" ]] || { echo "PHP is missing cassandra module. Installation failed." ; exit 5 ; }
fi

echo "Cassandra PHP extension installation successful."
