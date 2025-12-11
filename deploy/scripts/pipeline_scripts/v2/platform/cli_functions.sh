#!/usr/bin/env bash

function setup_dependencies() {
    # For CLI usage, just ensure CLI tools are installed
    az --version > /dev/null 2>&1 || echo "WARNING: Azure CLI not found, please install it"
}

function exit_error() {
    MESSAGE="$(caller | awk '{print $2":"$1} ') $1"
    ERROR_CODE=$2

    echo "ERROR: ${MESSAGE}"
    exit $ERROR_CODE
}

function log_warning() {
    MESSAGE=$1

    echo "WARNING: ${MESSAGE}"
}

function start_group() {
    MESSAGE=$1

    echo "=== ${MESSAGE} ==="
}

function end_group() {
    echo "=== END ==="
}

function commit_changes() {
    message=$1
    is_custom_message=${2:-false}

    # For CLI usage, just display what would be committed
    echo "Would commit changes with message: ${message}"
    echo "Use 'git commit -m \"${message}\" && git push' to actually commit the changes"
}

function __get_value_with_key() {
    key=$1

    # For CLI usage, try to read from environment variables
    value_var=$(echo "${key}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    value=${!value_var}

    if [ -z "$value" ]; then
        # Try to read from a local file
        if [ -f ".env" ]; then
            value=$(grep -h "^${key}=" .env | cut -d= -f2-)
        fi
    fi

    echo $value
}

function __set_value_with_key() {
    key=$1
    value=$2

    echo "CLI mode: Would set ${key}=${value}"

    # Store in .env file for persistence
    if [ -f ".env" ]; then
        if grep -q "^${key}=" .env; then
            sed -i "s/^${key}=.*/${key}=${value}/" .env
        else
            echo "${key}=${value}" >> .env
        fi
    else
        echo "${key}=${value}" > .env
    fi
}

function __get_secret_with_key() {
    key=$1

    # For CLI usage, try to read from environment variables
    secret_var=$(echo "${key}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    secret=${!secret_var}

    if [ -z "$secret" ]; then
        # Try to read from a local file
        if [ -f ".env.secrets" ]; then
            secret=$(grep -h "^${key}=" .env.secrets | cut -d= -f2-)
        fi
    fi

    echo $secret
}

function __set_secret_with_key() {
    key=$1
    value=$2

    echo "CLI mode: Would set secret ${key}=[REDACTED]"

    # Store in .env.secrets file for persistence with restricted permissions
    if [ -f ".env.secrets" ]; then
        if grep -q "^${key}=" .env.secrets; then
            sed -i "s/^${key}=.*/${key}=${value}/" .env.secrets
        else
            echo "${key}=${value}" >> .env.secrets
        fi
    else
        echo "${key}=${value}" > .env.secrets
        chmod 600 .env.secrets
    fi
}

function upload_summary() {
    summary=$1
    echo "CLI Summary: ${summary}"
}

function output_variable() {
    name=$1
    value=$2

    echo "OUTPUT: ${name}=${value}"
    # Also export it so it's available in the calling shell
    export "${name}"="${value}"
}
