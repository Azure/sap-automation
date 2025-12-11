#!/usr/bin/env bash

# Fail on any error, undefined variable, or pipeline failure
set -euo pipefail

# Enable debug mode if DEBUG is set to 'true'
if [[ "${SYSTEM_DEBUG:-false}" == 'true' || "${RUNNER_DEBUG:-0}" == "1" ]]; then
	# Enable debugging
	set -x
	# Exit on error
	set -o errexit
	echo "Environment variables:"
	printenv | sort
	DEBUG=true
else
	DEBUG=false
fi

export DEBUG


# This file provides platform detection and configuration for V2 scripts
# to support both Azure DevOps and GitHub Actions

# Detect platform
detect_platform() {
	if [ -n "${GITHUB_ACTIONS+x}" ]; then
		PLATFORM="github"
	elif [ -n "${TF_BUILD+x}" ]; then
		PLATFORM="devops"
	else
		# Default to CLI for interactive use
		PLATFORM="cli"
	fi
	export PLATFORM
	echo "Using platform:                      ${PLATFORM}"

}

# Load platform-specific functions
load_platform_functions() {
	local platform_dir
	platform_dir="$(dirname "${BASH_SOURCE[0]}")/platform"

	if [ "${PLATFORM}" == "github" ]; then
		source "${platform_dir}/github_functions.sh"
	elif [ "${PLATFORM}" == "devops" ]; then
		source "${platform_dir}/devops_functions.sh"
	else
		# Load a minimal set of functions for CLI usage
		source "${platform_dir}/cli_functions.sh" 2>/dev/null ||
			source "${platform_dir}/github_functions.sh" # Fallback to GitHub functions
	fi
}

# Configure environment variables for different platforms
configure_platform_variables() {
	# Common variables that need remapping between platforms
	if [ "${PLATFORM}" == "github" ]; then
		# Map GitHub Actions variables to common names
		[ ! -v SAP_AUTOMATION_REPO_PATH ] && export SAP_AUTOMATION_REPO_PATH="${GITHUB_WORKSPACE}/sap-automation"
		[ ! -v CONFIG_REPO_PATH ] && export CONFIG_REPO_PATH="${GITHUB_WORKSPACE}/WORKSPACES"
		#export APP_TOKEN="${GITHUB_TOKEN}"

		# Setup output for GitHub Actions
		export GITHUB_OUTPUT=${GITHUB_OUTPUT:-/dev/null}
	elif [ "${PLATFORM}" == "devops" ]; then
		# Map Azure DevOps variables to common names
		[ ! -v SAP_AUTOMATION_REPO_PATH ] && export SAP_AUTOMATION_REPO_PATH="${SYSTEM_DEFAULTWORKINGDIRECTORY}/sap-automation"
		[ ! -v CONFIG_REPO_PATH ] && export CONFIG_REPO_PATH="${SYSTEM_DEFAULTWORKINGDIRECTORY}/WORKSPACES}"
		export DEVOPS_PAT="${AZURE_DEVOPS_EXT_PAT:-${SYSTEM_ACCESSTOKEN:-}}"
	fi

	# Setup common paths for scripts
	export SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
	export SHARED_FUNCTIONS_FILE="${SCRIPT_DIR}/shared_functions_v2.sh"
}

# Set output variables in a platform-agnostic way
set_output_variable() {
	local name=$1
	local value=$2

	if [ "${PLATFORM}" == "github" ]; then
		echo "${name}=${value}" >>${GITHUB_OUTPUT}
	elif [ "${PLATFORM}" == "devops" ]; then
		echo "##vso[task.setvariable variable=${name};isOutput=true]${value}"
	fi

	# Also export it for local shell usage
	export "${name}=${value}"
}

# Initialize platform detection and configuration
init_platform() {
	detect_platform
	configure_platform_variables
	load_platform_functions

	# Source shared functions if file exists
	if [ -f "${SHARED_FUNCTIONS_FILE}" ]; then
		source "${SHARED_FUNCTIONS_FILE}"
	fi
}

# Initialize the platform automatically when this file is sourced
init_platform
