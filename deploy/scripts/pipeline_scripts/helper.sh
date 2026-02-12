#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function print_banner() {
	local title="$1"
	local message="$2"

	local length=${#message}
	if ((length % 2 == 0)); then
		message="$message "
	else
		message="$message"
	fi

	length=${#title}
	if ((length % 2 == 0)); then
		title="$title "
	else
		title="$title"
	fi

	local type="${3:-info}"
	local secondary_message="${4:-''}"
	local tertiary_message="${5:-''}"

	length=${#secondary_message}
	if ((length % 2 == 0)); then
		secondary_message="$secondary_message "
	else
		secondary_message="$secondary_message"
	fi

	length=${#tertiary_message}
	if ((length % 2 == 0)); then
		tertiary_message="$tertiary_message "
	else
		tertiary_message="$tertiary_message"
	fi

	local boldred="\e[1;31m"
	local cyan="\e[1;36m"
	local green="\e[1;32m"
	local reset="\e[0m"
	local yellow="\e[0;33m"

	local color
	case "$type" in
	error)
		color="$boldred"
		;;
	success)
		color="$green"
		;;
	warning)
		color="$yellow"
		;;
	info)
		color="$cyan"
		;;
	*)
		color="$cyan"
		;;
	esac

	local width=80
	local padding_title=$(((width - ${#title}) / 2))
	local padding_message=$(((width - ${#message}) / 2))
	local padding_secondary_message=$(((width - ${#secondary_message}) / 2))

	local centered_title
	local centered_message
	centered_title=$(printf "%*s%s%*s" $padding_title "" "$title" $padding_title "")
	centered_message=$(printf "%*s%s%*s" $padding_message "" "$message" $padding_message "")

	echo ""
	echo -e "${color}"
	echo "#################################################################################"
	echo "#                                                                               #"
	echo -e "#${color}${centered_title}${reset}#"
	echo "#                                                                               #"
	echo -e "#${color}${centered_message}${reset}#"
	echo "#                                                                               #"

	if [ ${#secondary_message} -gt 3 ]; then
		local centered_secondary_message
		centered_secondary_message=$(printf "%*s%s%*s" $padding_secondary_message "" "$secondary_message" $padding_secondary_message "")
		echo -e "#${color}${centered_secondary_message}${reset}#"
		echo "#                                                                               #"
	fi
	if [ ${#tertiary_message} -gt 3 ]; then
		local centered_tertiary_message
		centered_tertiary_message=$(printf "%*s%s%*s" $padding_tertiary_message "" "$tertiary_message" $padding_tertiary_message "")
		echo -e "#${color}${centered_tertiary_message}${reset}#"
		echo "#                                                                               #"
	fi
	echo "#################################################################################"
	echo -e "${reset}"
	echo ""
}

function getVariableFromVariableGroup() {
	local variable_group_id="$1"
	local variable_name="$2"
	local environment_file_name="$3"
	local environment_variable_name="$4"
	local variable_value

	variable_value=$(az pipelines variable-group variable list --group-id "${variable_group_id}" --query "${variable_name}.value" --output tsv)
	if [ -z "${variable_value}" ]; then
		if [ -f "${environment_file_name}" ]; then
			variable_value=$(grep "^$environment_variable_name" "${environment_file_name}" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"' || true)
			sourced_from_file=1
			export sourced_from_file
		fi
	fi

	echo "$variable_value"
}

function saveVariableInVariableGroup() {
	local variable_group_id="$1"
	local variable_name="$2"
	local variable_value="$3"
	local local_return_code=0

	if [ -n "$variable_value" ]; then

		print_banner "Saving variable" "Variable name: $variable_name" "info" "Variable value: $variable_value"

		az_var=$(az pipelines variable-group variable list --group-id "${variable_group_id}" --query "${variable_name}.value" --out tsv)
		if [ "$DEBUG" = True ]; then
			echo "Variable value: $az_var"
			echo "Variable length: ${#az_var}"
		fi
		if [ ${#az_var} -gt 0 ]; then
			az pipelines variable-group variable update --group-id "${variable_group_id}" --name "${variable_name}" --value "${variable_value}" --output none --only-show-errors
			local_return_code=$?
		else
			az pipelines variable-group variable create --group-id "${variable_group_id}" --name "${variable_name}" --value "${variable_value}" --output none --only-show-errors
			local_return_code=$?
		fi
	else
		az_var=$(az pipelines variable-group variable list --group-id "${variable_group_id}" --query "${variable_name}.value" --out tsv)
		if [ "$DEBUG" = True ]; then
			echo "Variable value: $az_var"
			echo "Variable length: ${#az_var}"
		fi
		if [ ${#az_var} -gt 0 ]; then
			az pipelines variable-group variable delete --group-id "${variable_group_id}" --name "${variable_name}" --yes --output none --only-show-errors
			local_return_code=$?
		fi
	fi
	return $local_return_code
}

function configureNonDeployer() {
	green="\e[1;32m"
	reset="\e[0m"
	local tf_version=$1
	local tf_url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip"

	isZipInstalled=$(which zip || true)
	if [ -z "$isZipInstalled" ]; then
		echo -e "$green--- Install zip ---$reset"
		sudo apt-get -qq install zip
	fi

	if ! which terraform; then
		if [ -n "$tf_version" ]; then
			echo -e "$green--- Install Terraform version $tf_version ---$reset"
			tf_url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip"
		else
			echo -e "$green--- Install latest Terraform ---$reset"
			tf_version=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version')
			tf_url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip"
		fi

		wget -q "$tf_url"
		return_code=$?
		if [ 0 != $return_code ]; then
			echo "##vso[task.logissue type=error]Unable to download Terraform version $tf_version."
			exit 2
		fi
		unzip -qq "terraform_${tf_version}_linux_amd64.zip"
		sudo mv terraform /bin/
		rm -f "terraform_${tf_version}_linux_amd64.zip"
	fi
}

function LogonToAzure() {
	local useMSI=$1
	local subscriptionId=$ARM_SUBSCRIPTION_ID

	if [ "$useMSI" != "true" ]; then
		echo "Deployment credentials:              Service Principal"
		echo "Deployment credential ID (SPN):      $ARM_CLIENT_ID"
		unset ARM_USE_MSI
		az login --service-principal --client-id "$ARM_CLIENT_ID" --password="$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" --output none
		echo "Logged on as:"
		az account show --query user --output yaml
		TF_VAR_use_spn=true
		export TF_VAR_use_spn

	else
		echo "Deployment credentials:              Managed Service Identity"
		if [ -f "/etc/profile.d/deploy_server.sh" ]; then
			echo "Sourcing deploy_server.sh to set up environment variables for MSI authentication"
			source "/etc/profile.d/deploy_server.sh"
		else
			echo "Running az login --identity"
			az login --identity --allow-no-subscriptions --client-id "$ARM_CLIENT_ID" --output none
		fi

		az account show --query user --output yaml

		TF_VAR_use_spn=false
		export TF_VAR_use_spn

		# sourcing deploy_server.sh overwrites ARM_SUBSCRIPTION_ID with control plane subscription id
		# ensure we are exporting the right ARM_SUBSCRIPTION_ID when authenticating against workload zones.
		if [[ "$ARM_SUBSCRIPTION_ID" != "$subscriptionId" ]]; then
			ARM_SUBSCRIPTION_ID=$subscriptionId
			export ARM_SUBSCRIPTION_ID
		fi
	fi

}

function get_region_from_code() {
	code_upper=$(echo "$1" | tr [:lower:] [:upper:] | xargs | tr -d '\r')
	case "$code_upper" in
	"AUCE") LOCATION_IN_FILENAME="australiacentral" ;;
	"AUC2") LOCATION_IN_FILENAME="australiacentral2" ;;
	"AUEA") LOCATION_IN_FILENAME="australiaeast" ;;
	"AUSE") LOCATION_IN_FILENAME="australiasoutheast" ;;
	"BRSO") LOCATION_IN_FILENAME="brazilsouth" ;;
	"BRSE") LOCATION_IN_FILENAME="brazilsoutheast" ;;
	"BRUS") LOCATION_IN_FILENAME="brazilus" ;;
	"CACE") LOCATION_IN_FILENAME="canadacentral" ;;
	"CAEA") LOCATION_IN_FILENAME="canadaeast" ;;
	"CEIN") LOCATION_IN_FILENAME="centralindia" ;;
	"CEUS") LOCATION_IN_FILENAME="centralus" ;;
	"CEUA") LOCATION_IN_FILENAME="centraluseuap" ;;
	"EAAS") LOCATION_IN_FILENAME="eastasia" ;;
	"EAUS") LOCATION_IN_FILENAME="eastus" ;;
	"EUSA") LOCATION_IN_FILENAME="eastus2euap" ;;
	"EUS2") LOCATION_IN_FILENAME="eastus2" ;;
	"EUSG") LOCATION_IN_FILENAME="eastusstg" ;;
	"FRCE") LOCATION_IN_FILENAME="francecentral" ;;
	"FRSO") LOCATION_IN_FILENAME="francesouth" ;;
	"GENO") LOCATION_IN_FILENAME="germanynorth" ;;
	"GEWE") LOCATION_IN_FILENAME="germanywest" ;;
	"GEWC") LOCATION_IN_FILENAME="germanywestcentral" ;;
	"INCE") LOCATION_IN_FILENAME="indonesiacentral" ;;
	"ISCE") LOCATION_IN_FILENAME="israelcentral" ;;
	"ITNO") LOCATION_IN_FILENAME="italynorth" ;;
	"JAEA") LOCATION_IN_FILENAME="japaneast" ;;
	"JAWE") LOCATION_IN_FILENAME="japanwest" ;;
	"JINC") LOCATION_IN_FILENAME="jioindiacentral" ;;
	"JINW") LOCATION_IN_FILENAME="jioindiawest" ;;
	"KOCE") LOCATION_IN_FILENAME="koreacentral" ;;
	"KOSO") LOCATION_IN_FILENAME="koreasouth" ;;
	"NCUS") LOCATION_IN_FILENAME="northcentralus" ;;
	"NOEU") LOCATION_IN_FILENAME="northeurope" ;;
	"NOEA") LOCATION_IN_FILENAME="norwayeast" ;;
	"NOWE") LOCATION_IN_FILENAME="norwaywest" ;;
	"NZNO") LOCATION_IN_FILENAME="newzealandnorth" ;;
	"PLCE") LOCATION_IN_FILENAME="polandcentral" ;;
	"QACE") LOCATION_IN_FILENAME="qatarcentral" ;;
	"SANO") LOCATION_IN_FILENAME="southafricanorth" ;;
	"SAWE") LOCATION_IN_FILENAME="southafricawest" ;;
	"SCUS") LOCATION_IN_FILENAME="southcentralus" ;;
	"SCUG") LOCATION_IN_FILENAME="southcentralusstg" ;;
	"SOEA") LOCATION_IN_FILENAME="southeastasia" ;;
	"SOIN") LOCATION_IN_FILENAME="southindia" ;;
	"SECE") LOCATION_IN_FILENAME="swedencentral" ;;
	"SWNO") LOCATION_IN_FILENAME="switzerlandnorth" ;;
	"SWWE") LOCATION_IN_FILENAME="switzerlandwest" ;;
	"UACE") LOCATION_IN_FILENAME="uaecentral" ;;
	"UANO") LOCATION_IN_FILENAME="uaenorth" ;;
	"UKSO") LOCATION_IN_FILENAME="uksouth" ;;
	"UKWE") LOCATION_IN_FILENAME="ukwest" ;;
	"WCUS") LOCATION_IN_FILENAME="westcentralus" ;;
	"WEEU") LOCATION_IN_FILENAME="westeurope" ;;
	"WEIN") LOCATION_IN_FILENAME="westindia" ;;
	"WEUS") LOCATION_IN_FILENAME="westus" ;;
	"WUS2") LOCATION_IN_FILENAME="westus2" ;;
	"WUS3") LOCATION_IN_FILENAME="westus3" ;;
	*) LOCATION_IN_FILENAME="westeurope" ;;
	esac
	echo "$LOCATION_IN_FILENAME"

}

function get_variable_group_id() {
	local variable_group_name="$1"
	local variable_group_id
	var_name="$2"

	unset GROUP_ID
	variable_group_id=$(az pipelines variable-group list --query "[?name=='$variable_group_name'].id | [0]" --output tsv)
	if [ -z "$variable_group_id" ]; then
		return 1
	fi

	echo ""
	echo -e "${green}Variable group information:"
	echo -e "--------------------------------------------------------------------------------${reset}"
	echo "Variable group name:                 $variable_group_name"
	echo "Variable group id:                   $variable_group_id"
	echo ""

	typeset -g "${var_name}" # declare the specified variable as global

	eval "${var_name}=${variable_group_id}" # set the variable in global context
	return 0
}

function print_header() {
	echo ""
	local green="\e[1;32m"
	local reset="\e[0m"
	echo ""
	if [ "${PLATFORM:-ado}" == "devops" ]; then

		echo -e "${green}DevOps information:"
		echo -e "-------------------------------------------------------------------------------$reset"

		echo "Agent pool:                          ${THIS_AGENT:-unknown}"
		echo "Organization:                        $SYSTEM_COLLECTIONURI"
		echo "Project:                             $SYSTEM_TEAMPROJECT"
		echo ""
		if printenv TF_VAR_agent_pat; then
			echo "Deployer Agent PAT:                  IsDefined"
		fi
		if printenv POOL; then
			echo "Deployer Agent Pool:                 $POOL"
		fi
	fi
	echo ""
	echo -e "${green}Azure CLI version:${reset}"
	echo -e "${green}-------------------------------------------------${reset}"
	az --version
	echo ""
	echo -e "${green}Terraform version:${reset}"
	echo -e "${green}-------------------------------------------------${reset}"
	if [ -f /opt/terraform/bin/terraform ]; then
		tfPath="/opt/terraform/bin/terraform"
	else
		tfPath=$(which terraform)
	fi

	if [ -n "$tfPath" ]; then
		"${tfPath}" --version || true
	fi

}

function configure_devops() {
	echo ""
	az config set extension.use_dynamic_install=yes_without_prompt --output none --only-show-errors
	az config set extension.dynamic_install_allow_preview=true --output none --only-show-errors

	if [ -n "${TF_BUILD+x}" ]; then

		echo -e "$green--- Configure devops CLI extension ---$reset"

		# Check if Azure DevOps extension is installed, if not, install it

		extension_installed=$(az extension list --query "[?contains(name, 'azure-devops')].name | [0]" --output tsv)

		if [ -n "$extension_installed" ]; then
			echo "Azure DevOps extension already installed."
			az extension update --name azure-devops --output none --only-show-errors
		else
			az extension add --name azure-devops --output none --only-show-errors
			echo "Azure DevOps extension installed."
		fi

		az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECTID" --output none
	fi

	extension_installed=$(az extension list --query "[?contains(name, 'resource-graph')].name | [0]" --output tsv)

	if [ -n "$extension_installed" ]; then
		echo "Azure Resource Graph extension already installed."
		az extension update --name resource-graph --output none --only-show-errors
	else
		az extension add --name resource-graph --output none --only-show-errors
		echo "Azure Resource Graph extension installed."
	fi
}

function remove_variable() {
	local variable_name="$2"
	local variable_group="$1"
	variable_value=$(az pipelines variable-group variable list --group-id "${variable_group}" --query "$variable_name.value" --out tsv)
	if [ ${#variable_value} != 0 ]; then
		az pipelines variable-group variable delete --group-id "${variable_group}" --name "$variable_name" --yes --only-show-errors
	fi
}
