#!/bin/bash
# Uploads a new binary for Cassandra-PHP-Driver as release to the GitHub repo
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[[ -f /proc/1/cgroup ]] && $(grep -q "docker" "/proc/1/cgroup") || { echo "Release script should run inside the Docker container because it requires a proper environment. Aborting.." ; exit 6 ; }

function testCmdInstalled() {
    for arg do
        [[ -x $(command -v "${arg}") ]] || { echo "${arg} command is not installed!" ; return 1 ; }
    done
    return 0
}

# Returns the response output of the request made to GitHub API
curlrepo () {
    local method="GET"
    local url="${github_api}/${project_full_name}"
    local post_data=
    local status_code_response=

    for ((i=1; i <= ${#@}; i++)); do
        local arg="${@:i:1}"
        local arg_value="${@:i+1:1}"

        # Handle current argument and skip over values that are used by the current argument
        case "${arg}" in
            --url|-u)
                url+="/${arg_value}"
                ((i++))
            ;;
            --method|-m)
                method=$(awk '{print toupper($0)}' <<< "${arg_value}")
                ((i++))
            ;;
            --data|-d)
                post_data="${arg_value}"
                ((i++))
            ;;
            --status|-s)
                status_code_response=true
            ;;
        esac
    done
    [[ "${method}" == "GET" && "${post_data}" != "" ]] && method="POST"

    local curl_args=(
        "--user" "${github_user}:${github_pass}"
        "--silent"
        "--header" "User-Agent: ${project_name} build"
        "--header" "Content-Type: application/json"
        "--request" "${method}"
    )

    if [[ "${method}" == 'POST' ]]; then
        if [[ "${post_data}" == "" ]]; then
            echo 'Error: Calling POST curlrepo without post data.'
            return 1
        fi
        curl_args+=("-d" "${post_data}")
    fi
    [[ "${status_code_response}" ]] && curl_args+=("--write-out" "%{http_code}\n" "--output" "/dev/null")

    curl \
        "${curl_args[@]}" \
        "${url}"
}

testCmdInstalled sort grep curl jq || { "Error: missing installed commands to continue.." ; exit 1 ; }

# Command configuration
project_owner="FlxOne"
project_name="cassandra-php-driver"
file_to_upload="${1}"
[[ -f "${file_to_upload}" ]] || { echo "File to upload does not exist: ${file_to_upload}. Working directory: ${dir}"; ls -al; exit 1; }
target_release_tag="${2}"

# Computed configuration
project_full_name="${project_owner}/${project_name}"
github_api="https://api.github.com/repos"
github_repo_url="git@github.com:${project_full_name}.git"

# User inputted configuration
echo "Enter your GitHub credentials that has access to ${project_full_name}:"
read -t 60 -p "Username: " github_user
[[ "${github_user}" != "" ]] || { echo "No GitHub username given." ; exit 1 ; }
read -t 60 -s -p "Password: " github_pass
[[ "${github_pass}" != "" ]] || { echo "No GitHub password given." ; exit 1 ; }
echo

# Retrieve release tag (either from command args or user input)
if [[ "${target_release_tag}" == "" ]]; then
    echo "Retrieving latest tag version from ${github_repo_url}.."
    latest_tag=$(curlrepo --url "releases/latest" | jq -r '.tag_name')
    if [[ -z ${latest_tag} ]]; then
        echo "Failed to get latest tag from github for the project ${project_full_name}."
    fi

    # Allow user to enter version or use auto incremented version if left empty
    read -e -p "Enter a tag name. Last tag was '${latest_tag}': " target_release_tag

    if [[ "${target_release_tag}" == "" ]]; then
        echo "Error: No tag name specified."
        exit 2
    fi
fi


# Delete GitHub release on the same tag if it exists
release_tag_response=$(curlrepo --url "releases/tags/${target_release_tag}")
release_id=$(jq '.id' <<<"${release_tag_response}")
if [[ "${release_id}" != 'null' ]]; then
    read -n1 -p "A release for ${target_release_tag} already exists. Do you want to replace it? (y/n): " replace_release_yesno

    if [[ ${replace_release_yesno} != 'y' ]]; then
        echo " Aborting release script because the tag already has a release."
        exit 0
    fi

    echo " Deleting release ${release_id}.."
    delete_status_code=$(curlrepo --method "DELETE" --status --url "releases/${release_id}")
    if (( ${delete_status_code} >= 300 )); then
        echo "Failed to delete release ${release_id} with tag ${target_release_tag}. Status code: ${delete_status_code}"
        exit 1
    else
        echo "Successfully deleted release ${release_id}. Status code: ${delete_status_code}"
    fi
fi

# Preparing new release on GitHub (asking GitHub for the upload url).
echo "Uploading release to github on tag ${target_release_tag}.."
release_post_json=$(
    jq -n \
        --arg tagname "${target_release_tag}" \
        --arg name "Build ${target_release_tag}" \
        --arg body "This is an automatic build." \
        '{tag_name: $tagname, name: $name, body: $body}'
)
release_response=$(curlrepo --url "releases" --data "${release_post_json}")
release_upload_url=$(jq -r '.upload_url' <<<"${release_response}")
if [[ "${release_upload_url}" == 'null' ]]; then
    echo "Failed to prepare new release on GitHub. upload_url missing from POST response. Response from GitHub: ${release_response}"
    exit 4
fi
release_upload_url="${release_upload_url%\{*}" # Remove the suffix that GitHub adds to the upload url
release_upload_url="${release_upload_url}?name=$(basename ${file_to_upload})"

# Uploading release to GitHub.
echo "Uploading ${file_to_upload} to ${release_upload_url}.."
file_upload_response=$(
    curl \
        --silent \
        --show-error \
        --user "${github_user}:${github_pass}" \
        --header "User-Agent: ${project_name} build" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @${file_to_upload} \
        "${release_upload_url}"
)

if [[ $(echo ${file_upload_response} | jq -r '.state') != 'uploaded' ]]; then
    echo "Failed to upload release files to GitHub for tag ${target_release_tag}. GitHub's response:"
    echo "${file_upload_response}"
    exit 5
fi
echo "Successfully uploaded new ${project_name} release ${target_release_tag} to GitHub"
