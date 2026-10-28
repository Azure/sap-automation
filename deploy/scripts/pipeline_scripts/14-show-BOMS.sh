#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Source the shared platform configuration
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

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
#call stack has full script name when using source
# shellcheck disable=SC1091
source "${parent_directory}/deploy_utils.sh"
source "${script_directory}/helper.sh"

SCRIPT_NAME="$(basename "$0")"

banner_title="Show Bill of Materials Files"

print_banner "$banner_title" "Entering $SCRIPT_NAME" "info"

# Print the execution environment details
print_header
echo ""


# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.17.0}"
fi
echo -e "$green--- az login ---$reset"
# Set logon variables
if [ "$USE_MSI" == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi

PLATFORM="devops"
LogonToAzure "${USE_MSI:-false}"
return_code=$?
if [ 0 != "$return_code" ]; then
	echo "##vso[task.logissue type=error]az login failed."
	exit "$return_code"
fi
az account show --output none
return_code=$?
if [ 0 != "$return_code" ]; then
	echo "##vso[task.logissue type=error]No authenticated Azure account is available."
	exit "$return_code"
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

PLATFORM="devops"
OUTPUT_DIR="${BUILD_REPOSITORY_LOCALPATH}"

output_file="$OUTPUT_DIR/DownloadedBOMs.md"

boms=$(az storage blob list --account-name $account --container sapbits --auth-mode login --query "[].name" --prefix sapfiles/boms --out tsv)
echo "List of Downloaded Bill of Materials files:"
printf "**List of Downloaded Bill of Materials files**\n\n\n" >"$output_file"

for bom in $boms; do
		if [[ "$bom" == *.original || "$bom" == *.yaml ]]; then
			name="${bom##*/}"
			name="${name%.original}"
			name="${name%.yaml}"
			echo "$name"
			printf " - %s\n" "$name" >>"$output_file"
		fi
done | sort -u


printf "\n\n" >>"$output_file"
echo "##vso[task.uploadsummary]${output_file}"
