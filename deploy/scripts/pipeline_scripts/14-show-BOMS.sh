#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Source the shared platform configuration
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
echo ${SCRIPT_DIR}

source "${SCRIPT_DIR}/v2/shared_platform_config.sh"
source "${SCRIPT_DIR}/shared_functions.sh"

SCRIPT_NAME="$(basename "$0")"

# Set platform-specific output
if [ "$PLATFORM" == "devops" ]; then
	echo "##vso[build.updatebuildnumber]Show the Bill of Materials Files"
fi

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"
#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"
source "${parent_directory}/helper.sh"

SCRIPT_NAME="$(basename "$0")"

banner_title="Show Bill of Materials Files"

print_banner "$banner_title" "Entering $SCRIPT_NAME" "info"

# Print the execution environment details
print_header
echo ""


# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.16.5}"
fi
echo -e "$green--- az login ---$reset"
# Set logon variables
if [ "$USE_MSI" == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi

if [ "$PLATFORM" == "devops" ]; then
	if [ "$USE_MSI" != "true" ]; then
		ARM_TENANT_ID=$(az account show --query tenantId --output tsv)
		export ARM_TENANT_ID
		ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
		export ARM_SUBSCRIPTION_ID
	else
		LogonToAzure "${USE_MSI:-false}"
		return_code=$?
		if [ 0 != $return_code ]; then
			echo -e "$bold_red--- Login failed ---$reset"
			echo "##vso[task.logissue type=error]az login failed."
			exit $return_code
		fi
	fi
fi


keyvault_name="$KEY_VAULT"
while [[ -z "$keyvault_name" ]]; do
    read -r -p "Enter Key Vault name: " keyvault_name || exit 1
done

url=$(az keyvault secret show --vault-name $keyvault_name \
                                        --name sapbits-location-base-path \
                                        --query value \
                                        --output tsv)

account="${url#*://}"    # Remove the scheme
account="${account%%.*}" # Keep everything before the first dot

boms=$(az storage blob list --account-name $account --container sapbits --auth-mode login --query "[].name" --prefix sapfiles/boms --out tsv)
echo "List of Downloaded Bill of Materials files:"
for bom in $boms; do
		if [[ "$bom" == *.original || "$bom" == *.yaml ]]; then
			name="${bom##*/}"
			name="${name%.original}"
			name="${name%.yaml}"
			echo "$name"
		fi
done | sort -u
