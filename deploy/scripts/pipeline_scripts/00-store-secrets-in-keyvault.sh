#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
SCRIPT_NAME="$(basename "$0")"

source "${parent_directory}/deploy_utils.sh"
set -e



if checkforDevOpsVar APPLICATION_CONFIGURATION_NAME; then
    echo ""
    echo "Running v2 script"
    export SDAFWZ_CALLER_VERSION="v2"
    echo ""
    "${script_directory}/v2/$SCRIPT_NAME"
    return_code=$?
else
    echo ""
    echo "Running v1 script"
    export SDAFWZ_CALLER_VERSION="v1"
    echo ""
    "${script_directory}/v1/$SCRIPT_NAME"
    return_code=$?
fi

echo "Return code: $return_code"
exit $return_code
