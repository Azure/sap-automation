#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

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

	az_var=$(az pipelines variable-group variable list --group-id "${variable_group_id}" --query "${variable_name}.value" --out tsv)
	if [ "$DEBUG" = True ]; then
		echo "Variable value: $az_var"
		echo "Variable length: ${#az_var}"
	fi
	if [ ${#az_var} -gt 0 ]; then
		az pipelines variable-group variable update --group-id "${variable_group_id}" --name "${variable_name}" --value "${variable_value}" --output none --only-show-errors
	else
		az pipelines variable-group variable create --group-id "${variable_group_id}" --name "${variable_name}" --value "${variable_value}" --output none --only-show-errors
	fi

}

function configureNonDeployer() {
	green="\e[1;32m"
	reset="\e[0m"
	local tf_version=$1
	local tf_url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip"

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
		az account show --query user --output table
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

		az account show --query user --output table

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
