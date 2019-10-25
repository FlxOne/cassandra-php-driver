#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function elementAt() {
    local arr=("${@:2}")
    local ind=${1:-0}

    (( ind > -1 && ind < ${#arr[@]} )) || { echo "" ; return ; }

    echo "${arr[${ind}]}"
}

function getBuildDirForSystem() {
    local systemName="${1}"
    echo $(find "${dirSystems}" -type d -maxdepth 1 -iname "${systemName}")
}

dirSystems="${dir}/resources/systems"
supportedSystems=($(echo "${dirSystems}/*/"))

# Validate environment for script
[[ -d "${dirSystems}" ]] || { echo "Directory '${dirSystems}' does not exist." ; exit 1 ; }
(( ${#supportedSystems[@]} > 1 )) || { echo "No directories with Dockerfiles to build Cassandra PHP driver found in '${dirSystems}'" ; exit 1 ; }
for system in "${supportedSystems[@]}"; do
    [[ -f "${system}/Dockerfile" ]] || { echo "Missing Dockerfile in directory '${system}'" ; exit 1 ; }
done

# Select system directly if provided as argument
selectedSystem=$(getBuildDirForSystem "${1}")
if [[ "${selectedSystem}" == "" ]]; then
    # If system was supplied but not correct then do not continue
    if [[ "${1}" != "" ]]; then
        echo "System name '${1}' is not supported."
        exit 2
    fi

    # Ask user to select a system
    selectedSystem=""
    if (( ${#supportedSystems[@]} > 1 )); then
        echo
        for i in "${!supportedSystems[@]}"; do
            system="${supportedSystems[${i}]}"
            echo "$((i+1)). $(basename "${system}")"
        done
        read -n1 -p "Enter a number to build for that system:" -s selectedIndex
        echo

        # Try get system from user inputted index
        ((selectedIndex--)) # Index starts at 0 instead of 1
        selectedSystem=$(elementAt "${selectedIndex}" "${supportedSystems[@]}")
        [[ -d "${selectedSystem}" ]] || { echo "Invalid number selected!" ; exit 2 ; }
    else
        selectedSystem="${supportedSystems[0]}"
    fi
fi

echo "Now building Cassandra PHP Driver for $(basename ${selectedSystem}).."
docker build \
    --tag=cassandra-php-driver:base \
    -f "${selectedSystem}/Dockerfile" \
    "${dir}/.."
