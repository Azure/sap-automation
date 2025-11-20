#!/usr/bin/env bash

function setup_dependencies() {
    git config --global --add safe.directory ${GITHUB_WORKSPACE}

    # Install Azure CLI extensions if needed
    az config set extension.use_dynamic_install=yes_without_prompt > /dev/null 2>&1

    echo "Working with environment: ${CONTROL_PLANE_NAME}"
}

function exit_error() {
    MESSAGE="$(caller | awk '{print $2":"$1} ') $1"
    ERROR_CODE=$2

    echo "::error::${MESSAGE}"
    exit $ERROR_CODE
}

function log_warning() {
    MESSAGE=$1

    echo "::warning::${MESSAGE}"
}

function start_group() {
    MESSAGE=$1

    echo "::group::${MESSAGE}"
}

function end_group() {
    echo "::endgroup::"
}

function commit_changes() {
    message=$1
    is_custom_message=${2:-false}

    git config --global user.email github-actions@github.com
    git config --global user.name github-actions

    if [[ $is_custom_message == "true" ]]; then
        git commit -m "${message}"
    else
        git commit -m "${message} - Workflow: ${GITHUB_WORKFLOW}:${GITHUB_RUN_NUMBER}-${GITHUB_RUN_ATTEMPT} [skip ci]"
    fi

    git push
}

function __get_value_with_key() {
    key=$1

    value=$(curl -Ss \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${APP_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -L "${GITHUB_API_URL}/repositories/${GITHUB_REPOSITORY_ID}/environments/${CONTROL_PLANE_NAME}/variables/${key}" | jq -r '.value // empty')

    echo $value
}

function __set_value_with_key() {
    key=$1
    new_value=$2

    old_value=$(__get_value_with_key ${key})

    echo "Saving value for key in environment variables ${CONTROL_PLANE_NAME}: ${key}"

    if [[ -z "${old_value}" ]]; then
        curl -Ss -o /dev/null \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${APP_TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            -L "${GITHUB_API_URL}/repositories/${GITHUB_REPOSITORY_ID}/environments/${CONTROL_PLANE_NAME}/variables" \
            -d "{\"name\":\"${key}\", \"value\":\"${new_value}\"}"

    elif [[ "${old_value}" != "${new_value}" ]]; then
        curl -Ss -o /dev/null \
            -X PATCH \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${APP_TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            -L "${GITHUB_API_URL}/repositories/${GITHUB_REPOSITORY_ID}/environments/${CONTROL_PLANE_NAME}/variables/${key}" \
            -d "{\"name\":\"${key}\", \"value\":\"${new_value}\"}"
    fi
}

function __get_secret_with_key() {
    key=$1

    # GitHub Actions doesn't allow direct access to secrets via API
    # We can only check if the secret exists
    status_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${APP_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -L "${GITHUB_API_URL}/repositories/${GITHUB_REPOSITORY_ID}/environments/${CONTROL_PLANE_NAME}/secrets/${key}")

    if [[ $status_code == "200" ]]; then
        echo "REDACTED_SECRET_EXISTS"
    else
        echo ""
    fi
}

function __set_secret_with_key() {
    key=$1
    value=$2

    echo "Saving secret value for key in environment : ${key}"

    # Get public key for the repository to encrypt the secret
    public_key_response=$(curl -Ss \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${APP_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -L "${GITHUB_API_URL}/repositories/${GITHUB_REPOSITORY_ID}/environments/${CONTROL_PLANE_NAME}/secrets/public-key")

    public_key=$(echo $public_key_response | jq -r .key)
    public_key_id=$(echo $public_key_response | jq -r .key_id)

    # Encrypt the secret using sodium (libsodium)
    # Note: In a real implementation, you would use a tool like libsodium to encrypt
    # For this script, we're assuming the value is already encrypted or using environment secrets

    # Check if secret exists
    status_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${APP_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -L "${GITHUB_API_URL}/repositories/${GITHUB_REPOSITORY_ID}/environments/${CONTROL_PLANE_NAME}/secrets/${key}")

    method="PUT"
    if [[ $status_code != "200" ]]; then
        method="POST"
    fi

    # Set up the actual secret using encrypted_value
    # This is a placeholder - in real implementation, we would encrypt the value
    curl -Ss -o /dev/null \
        -X $method \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${APP_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -L "${GITHUB_API_URL}/repositories/${GITHUB_REPOSITORY_ID}/environments/${CONTROL_PLANE_NAME}/secrets/${key}" \
        -d "{\"encrypted_value\":\"ENCRYPTED_VALUE\", \"key_id\":\"${public_key_id}\"}"
}

function upload_summary() {
    summary=$1
    if [[ -f $GITHUB_STEP_SUMMARY ]]; then
        cat $summary >> $GITHUB_STEP_SUMMARY
    else
        echo $summary >> $GITHUB_STEP_SUMMARY
    fi
}

function output_variable() {
    name=$1
    value=$2

    echo "${name}=${value}" >> $GITHUB_OUTPUT
}
