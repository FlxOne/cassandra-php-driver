#!/usr/bin/env bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Returns the element of the array given array. First argument is index, second argument is the array.
function elementAt() {
    local ind=${1:-0}
    local arr=("${@:2}")

    (( ind > -1 && ind < ${#arr[@]} )) && echo "${arr[${ind}]}"
}

# Finds the directory of a supported system from a name or returns empty string if system is not supported.
function getBuildDirForSystem() {
    local systemName="${1}"
    echo $(find "${dirSystems}" -type d -maxdepth 1 -iname "${systemName}")
}


function isArg() {
    local arg="${1}"
    [[ "${arg}" =~ ^--[a-zA-Z]+ ]]
}

storeInVar=
preferredSystem=
for arg in "${@}"; do
    argValue="${2}"
    argIsHandled=true
    case "${arg}" in
        --system)
            isArg "${argValue}" && { echo "Expected value '${argValue}' to not be an argument" ; exit 1 ; }
            preferredSystem="${argValue}"
            shift
        ;;
        --store|-s)
            isArg "${argValue}" && { echo "Expected value '${argValue}' to not be an argument" ; exit 1 ; }
            storeInVar="${argValue}"
            shift
        ;;
        --resources|-r)
            isArg "${argValue}" && { echo "Expected value '${argValue}' to not be an argument" ; exit 1 ; }
            [[ "${argValue}" != "" && -d "${argValue}" ]] || { echo "Expected resources to be a valid directory." ; exit 1 ; }
            dir="${argValue}"
            shift
        ;;
        --*|-*)
            echo "Invalid argument given: ${arg}"
            exit 1
        ;;
        *)
            argIsHandled=false
        ;;
    esac

    [[ "${argIsHandled}" == "true" ]] && shift
done

dirSystems="${dir}/systems"
supportedSystems=($(echo "${dirSystems}/*/"))

# Validate environment for script
[[ -d "${dirSystems}" ]] || { echo "Directory '${dirSystems}' does not exist." ; exit 1 ; }
(( ${#supportedSystems[@]} > 1 )) || { echo "No directories with Dockerfiles to build Cassandra PHP driver found in '${dirSystems}'" ; exit 1 ; }
for system in "${supportedSystems[@]}"; do
    [[ -f "${system}/Dockerfile" ]] || { echo "Missing Dockerfile in directory '${system}'" ; exit 1 ; }
done

# Select system directly if provided as argument
selectedSystem=$(getBuildDirForSystem "${preferredSystem}")
if [[ "${selectedSystem}" == "" ]]; then
    # If system was supplied but not correct then do not continue
    if [[ "${1}" != "" ]]; then
        echo "Unsupported or unknown system '${1}'."
        exit 2
    fi

    # Ask user to select a system
    selectedSystem=""
    if (( ${#supportedSystems[@]} > 1 )); then
        # Show system list for selection
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

# Store system path in variable and export it to calling script
if [[ "${storeInVar}" =~ ^[a-zA-Z][a-zA-Z\\-_]*$ ]]; then
    declare ${storeInVar}="${selectedSystem}"
elif [[ "${storeInVar}" != "" ]]; then
    echo "Invalid variable name to store: '${storeInVar}'."
    exit 1
fi
