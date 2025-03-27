#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################
#                                                                                              #
#   This file contains the logic to deploy the environment to support SAP workloads.           #
#                                                                                              #
#   The script is intended to be run from a parent folder to the folders containing            #
#   the json parameter files for the deployer, the library and the environment.                #
#                                                                                              #
#   The script will persist the parameters needed between the executions in the                #
#   $CONFIG_REPO_PATH/.sap_deployment_automation folder                                        #
#                                                                                              #
#   The script experts the following exports:                                                  #
#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                             #
#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation       #
#   CONFIG_REPO_PATH the path to the folder containing the configuration for sap               #
#                                                                                              #
################################################################################################

#error codes include those from /usr/include/sysexits.h

#colors for terminal
bold_red_underscore="\e[1;4;31m"
bold_red="\e[1;31m"
cyan="\e[1;36m"
reset_formatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$path
fi

#call stack has full scriptname when using source
source "${script_directory}/deploy_utils.sh"

#helper files
source "${script_directory}/helpers/script_helpers.sh"

force=0
step=0
recover=0
ado_flag="none"
deploy_using_msi_only=0

INPUT_ARGUMENTS=$(getopt -n deploy_controlplane -o d:l:s:c:p:t:a:k:ifohrvm --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,spn_id:,spn_secret:,tenant_id:,storageaccountname:,vault:,auto-approve,force,only_deployer,help,recover,ado,msi -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	control_plane_showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-a | --storageaccountname)
		REMOTE_STATE_SA="$2"
		shift 2
		;;
	-c | --spn_id)
		client_id="$2"
		shift 2
		;;
	-d | --deployer_parameter_file)
		deployer_parameter_file="$2"
		shift 2
		;;
	-k | --vault)
		keyvault="$2"
		shift 2
		;;
	-l | --library_parameter_file)
		library_parameter_file="$2"
		shift 2
		;;
	-p | --spn_secret)
		client_secret="$2"
		shift 2
		;;
	-s | --subscription)
		subscription="$2"
		shift 2
		;;
	-t | --tenant_id)
		tenant_id="$2"
		shift 2
		;;
	-f | --force)
		force=1
		shift
		;;
	-i | --auto-approve)
		approve="--auto-approve"
		autoApproveParameter="--auto-approve"
		shift
		;;
	-m | --msi)
		deploy_using_msi_only=1
		shift
		;;
	-o | --only_deployer)
		only_deployer=1
		shift
		;;
	-r | --recover)
		recover=1
		shift
		;;
	-v | --ado)
		ado_flag="--ado"
		shift
		;;
	-h | --help)
		control_plane_showhelp
		exit 3
		;;
	--)
		shift
		break
		;;
	esac
done

if [ "$DEBUG" = True ]; then
	# Enable debugging
	set -x
	# Exit on error
	set -o errexit
fi

echo "ADO flag:                            ${ado_flag}"

if [ "$ado_flag" == "--ado" ] || [ "$approve" == "--auto-approve" ]; then
	echo "Approve:                             Automatically"
fi

key=$(basename "${deployer_parameter_file}" | cut -d. -f1)
deployer_tfstate_key="${key}.terraform.tfstate"

echo "Deployer State File:                 ${deployer_tfstate_key}"
echo "Deployer Subscription:               ${subscription}"

key=$(basename "${library_parameter_file}" | cut -d. -f1)
library_tfstate_key="${key}.terraform.tfstate"

echo "Deployer State File:                 ${deployer_tfstate_key}"
echo "Library State File:                  ${library_tfstate_key}"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
root_dirname=$(pwd)

if [ ! -f /etc/profile.d/deploy_server.sh ]; then
	export TF_VAR_Agent_IP=$this_ip
fi

if [ ! -f "$deployer_parameter_file" ]; then
	control_plane_missing 'deployer parameter file'
	exit 2 #No such file or directory
fi

if [ ! -f "$library_parameter_file" ]; then
	control_plane_missing 'library parameter file'
	exit 2 #No such file or directory
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
	echo "validate_dependencies returned $return_code"
	exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$deployer_parameter_file"
if [ 0 != $return_code ]; then
	echo "Errors in parameter file" >"${deployer_config_information}".err
	exit $return_code
fi

# Convert the region to the correct code
get_region_code "$region"

echo "Region code:                         ${region_code}"

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config
deployer_config_information="${automation_config_directory}"/"${environment}""${region_code}"

if [ $force == 1 ]; then
	if [ -f "${deployer_config_information}" ]; then
		rm "${deployer_config_information}"
	fi
fi

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

save_config_var "deployer_tfstate_key" "${deployer_config_information}"

if [ -z "${keyvault}" ]; then
	load_config_vars "${deployer_config_information}" "keyvault"
fi

# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
	echo "Missing exports" >"${deployer_config_information}".err
	exit $return_code
fi
# Check that webapp exports are defined, if deploying webapp
if [ -n "${TF_VAR_use_webapp}" ]; then
	if [ "${TF_VAR_use_webapp}" == "true" ]; then
		validate_webapp_exports
		return_code=$?
		if [ 0 != $return_code ]; then
			exit $return_code
		fi
	fi
fi

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

library_dirname=$(dirname "${library_parameter_file}")
library_file_parametername=$(basename "${library_parameter_file}")

relative_path="${deployer_dirname}"
TF_DATA_DIR="${relative_path}"/.terraform
export TF_DATA_DIR

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                   $cyan Starting the control plane deployment $reset_formatting                             #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""
noAccess=$(az account show --query name | grep "N/A(tenant level account)" || true)

if [ -n "$noAccess" ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#        $bold_red The provided credentials do not have access to the subscription!!! $reset_formatting           #"
	echo "#                                                                                       #"
	echo "#########################################################################################"

	az account show --output table

	exit 65
fi
az account list --query "[].{Name:name,Id:id}" --output table
#setting the user environment variables
if [ -n "${subscription}" ]; then
	if is_valid_guid "$subscription"; then
		echo ""
	else
		printf -v val %-40.40s "$subscription"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#   The provided subscription is not valid:$bold_red ${val} $reset_formatting#   "
		echo "#                                                                                       #"
		echo "#########################################################################################"

		echo "The provided subscription is not valid: ${subscription}" >"${deployer_config_information}".err

		exit 65
	fi
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#       $cyan Changing the subscription to: $subscription $reset_formatting            #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	if [ 0 = "${deploy_using_msi_only:-}" ]; then
		echo "Identity to use:                     Service Principal"
		TF_VAR_use_spn=true
		export TF_VAR_use_spn

		#set_executing_user_environment_variables "${client_secret}"
	else
		echo "Identity to use:                     Managed Identity"
		TF_VAR_use_spn=false
		export TF_VAR_use_spn
		#set_executing_user_environment_variables "none"
	fi

	if [ $recover == 1 ]; then
		if [ -n "$REMOTE_STATE_SA" ]; then
			save_config_var "REMOTE_STATE_SA" "${deployer_config_information}"
			getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${deployer_config_information}"
			#Support running deploy_controlplane on new host when the resources are already deployed
			step=3
			save_config_var "step" "${deployer_config_information}"
		fi
	fi

	#Persist the parameters
	if [ -n "$subscription" ]; then
		save_config_var "subscription" "${deployer_config_information}"
		export STATE_SUBSCRIPTION=$subscription
		save_config_var "STATE_SUBSCRIPTION" "${deployer_config_information}"
		export ARM_SUBSCRIPTION_ID=$subscription
		save_config_var "ARM_SUBSCRIPTION_ID" "${deployer_config_information}"
	fi

	if [ -n "$client_id" ]; then
		save_config_var "client_id" "${deployer_config_information}"
	fi

	if [ -n "$tenant_id" ]; then
		save_config_var "tenant_id" "${deployer_config_information}"
	fi
fi

current_directory=$(pwd)

##########################################################################################
#                                                                                        #
#                                      STEP 0                                            #
#                           Bootstrapping the deployer                                   #
#                                                                                        #
#                                                                                        #
##########################################################################################

load_config_vars "${deployer_config_information}" "step"
if [ -z "${step}" ]; then
	step=0
fi
echo "Step:                                $step"

if [ 0 == "$step" ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                          $cyan Bootstrapping the deployer $reset_formatting                                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	allParameters=$(printf " --parameterfile %s %s" "${deployer_file_parametername}" "${autoApproveParameter}")

	cd "${deployer_dirname}" || exit

	echo "Calling install_deployer.sh:         $allParameters"
	echo "Deployer State File:                 ${deployer_tfstate_key}"

	if [ "$ado_flag" == "--ado" ] || [ "$approve" == "--auto-approve" ]; then

		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_deployer.sh" \
			--parameterfile "${deployer_file_parametername}" --auto-approve; then
			echo "Bootstrapping of the deployer failed"
			step=0
			save_config_var "step" "${deployer_config_information}"
			exit 10
		fi
	else
		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_deployer.sh" \
			--parameterfile "${deployer_file_parametername}"; then
			echo "Bootstrapping of the deployer failed"
			step=0
			save_config_var "step" "${deployer_config_information}"
			exit 10
		fi
	fi
	return_code=$?

	echo "Return code from install_deployer:   ${return_code}"
	if [ 0 != $return_code ]; then
		echo "Bootstrapping of the deployer failed" >"${deployer_config_information}".err
		step=0
		save_config_var "step" "${deployer_config_information}"
		exit 10
	else
		step=1
		save_config_var "step" "${deployer_config_information}"

		load_config_vars "${deployer_config_information}" "step"
		echo "Step:                                $step"

		if [ 1 = "${only_deployer:-}" ]; then
			exit 0
		fi
	fi

	load_config_vars "${deployer_config_information}" "keyvault"
	echo "Key vault:             ${keyvault}"

	if [ -z "$keyvault" ]; then
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                       $bold_red  Bootstrapping of the deployer failed $reset_formatting                         #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo "Bootstrapping of the deployer failed" >"${deployer_config_information}".err
		exit 10
	fi
	if [ "$FORCE_RESET" = True ]; then
		step=0
		save_config_var "step" "${deployer_config_information}"
		exit 0
	else
		export step=1
	fi
	save_config_var "step" "${deployer_config_information}"

	cd "$root_dirname" || exit

	load_config_vars "${deployer_config_information}" "sshsecret"
	load_config_vars "${deployer_config_information}" "keyvault"
	load_config_vars "${deployer_config_information}" "deployer_public_ip_address"

	echo "##vso[task.setprogress value=20;]Progress Indicator"
else
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                          $cyan Deployer is bootstrapped $reset_formatting                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	echo "##vso[task.setprogress value=20;]Progress Indicator"
fi

cd "$root_dirname" || exit

##########################################################################################
#                                                                                        #
#                                     Step 1                                             #
#                           Validating Key Vault Access                                  #
#                                                                                        #
#                                                                                        #
##########################################################################################
echo "Validating Key Vault Access"
echo "Step:                                $step"

TF_DATA_DIR="${deployer_dirname}"/.terraform
export TF_DATA_DIR

cd "${deployer_dirname}" || exit
if [ 0 != "$step" ]; then

	if [ 1 == "$step" ] || [ 3 = "$step" ]; then
		# If the keyvault is not set, check the terraform state file
		if [ -z "$keyvault" ]; then
			key=$(echo "${deployer_file_parametername}" | cut -d. -f1)

			if [ -f ./.terraform/terraform.tfstate ]; then
				azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
				if [ -n "$azure_backend" ]; then
					echo "Terraform state:                     remote"

					terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/run/sap_deployer/
					terraform -chdir="${terraform_module_directory}" init -upgrade=true

					keyvault=$(terraform -chdir="${terraform_module_directory}" output deployer_kv_user_name | tr -d \")
					save_config_var "keyvault" "${deployer_config_information}"
				else
					echo "Terraform state:                     local"
				fi
			fi
		fi

		if [ -z "$keyvault" ]; then
			if [ $ado_flag != "--ado" ]; then
				read -r -p "Deployer keyvault name: " keyvault
			else
				exit 10
			fi
		fi

		if [ 1 -eq $step ] && [ -n "$client_secret" ]; then

			if "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh \
				--environment "${environment}" \
				--region "${region_code}" \
				--vault "${keyvault}" \
				--spn_id "${client_id}" \
				--spn_secret "${client_secret}" \
				--tenant_id "${tenant_id}"; then
				echo ""
				echo -e "${cyan}Set secrets:                           succeeded$reset_formatting"
				echo ""
			else
				echo -e "${bold_red}Set secrets:                           succeeded$reset_formatting"
				exit 10
			fi
		fi

	fi
else
	if [ -z "$keyvault" ]; then
		load_config_vars "${deployer_config_information}" "keyvault"
	fi
fi
if [ -n "${keyvault}" ] && [ 0 != "$step" ]; then

	echo "Checking for keyvault:               ${keyvault}"

	kv_found=$(az keyvault show --name="$keyvault" --subscription "${subscription}" --query name)
	if [ -z "${kv_found}" ]; then
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                            $bold_red  Detected a failed deployment $reset_formatting                            #"
		echo "#                                                                                       #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		exit 10
	else
		TF_VAR_deployer_kv_user_arm_id=$(az keyvault show --name="$keyvault" --subscription "${subscription}" --query id)
		export TF_VAR_deployer_kv_user_arm_id
	fi
else
	if [ $ado_flag != "--ado" ]; then
		read -r -p "Deployer keyvault name: " keyvault
		save_config_var "keyvault" "${deployer_config_information}"
	else
		step=0
		save_config_var "step" "${deployer_config_information}"
		exit 10
	fi

fi

unset TF_DATA_DIR

cd "$root_dirname" || exit

az account set --subscription "$ARM_SUBSCRIPTION_ID"

if validate_key_vault "$keyvault" "$ARM_SUBSCRIPTION_ID"; then
	echo "Key vault:                           ${keyvault}"
	save_config_var "keyvault" "${deployer_config_information}"
	if [ 1 -eq $step ]; then
		export step=2
		save_config_var "step" "${deployer_config_information}"
	fi

else
	return_code=$?
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                       $bold_red  Key vault not found $reset_formatting                                      #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
fi

##########################################################################################
#                                                                                        #
#                                      STEP 2                                            #
#                           Bootstrapping the library                                    #
#                                                                                        #
#                                                                                        #
##########################################################################################

if [ 2 -eq $step ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                          $cyan Bootstrapping the library $reset_formatting                                  #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	relative_path="${library_dirname}"
	export TF_DATA_DIR="${relative_path}/.terraform"
	relative_path="$CONFIG_REPO_PATH/${deployer_dirname}"

	cd "${library_dirname}" || exit
	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/

	if [ $force == 1 ]; then
		rm -Rf .terraform terraform.tfstate*
	fi

	echo "Calling install_library.sh with: --parameterfile ${library_file_parametername} --deployer_statefile_foldername ${relative_path} --keyvault ${keyvault} ${autoApproveParameter}"

	if [ "$ado_flag" == "--ado" ] || [ "$approve" == "--auto-approve" ]; then

		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_library.sh" \
			--parameterfile "${library_file_parametername}" \
			--deployer_statefile_foldername "${relative_path}" \
			--keyvault "${keyvault}" --auto-approve; then
			echo "Bootstrapping of the SAP Library failed"
			step=2
			save_config_var "step" "${deployer_config_information}"
			exit 20
		else
			step=3
			save_config_var "step" "${deployer_config_information}"

		fi
	else
		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_library.sh" \
			--parameterfile "${library_file_parametername}" \
			--deployer_statefile_foldername "${relative_path}" \
			--keyvault "${keyvault}"; then
			return_code=$?
			echo "Bootstrapping of the SAP Library failed"

			step=2
			save_config_var "step" "${deployer_config_information}"
			exit 20
		else
			return_code=$?
			step=3
			save_config_var "step" "${deployer_config_information}"
		fi
	fi

	if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

		if [ -z "$REMOTE_STATE_SA" ]; then
			REMOTE_STATE_RG=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sapbits_sa_resource_group_name | tr -d \")
		fi
		if [ -z "$REMOTE_STATE_SA" ]; then
			REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")
		fi
		if [ -z "$STATE_SUBSCRIPTION" ]; then
			STATE_SUBSCRIPTION=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_subscription_id | tr -d \")
		fi

		if [ "${ado_flag}" != "--ado" ]; then
			az storage account network-rule add -g "${REMOTE_STATE_RG}" --account-name "${REMOTE_STATE_SA}" --ip-address "${this_ip}" --output none
		fi

		TF_VAR_sa_connection_string=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sa_connection_string | tr -d \")
		export TF_VAR_sa_connection_string
	fi
	if [ -n "${tfstate_resource_id}" ]; then
		TF_VAR_tfstate_resource_id="${tfstate_resource_id}"
		export TF_VAR_tfstate_resource_id
	else
		tfstate_resource_id=$(az resource list --name "$REMOTE_STATE_SA" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
		TF_VAR_tfstate_resource_id=$tfstate_resource_id
	fi
	export TF_VAR_tfstate_resource_id

	cd "${current_directory}" || exit
	save_config_var "step" "${deployer_config_information}"
	echo "##vso[task.setprogress value=60;]Progress Indicator"

else
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                           $cyan Library is bootstrapped $reset_formatting                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	echo "##vso[task.setprogress value=60;]Progress Indicator"

fi

unset TF_DATA_DIR
cd "$root_dirname" || exit
echo "##vso[task.setprogress value=80;]Progress Indicator"

##########################################################################################
#                                                                                        #
#                                      STEP 3                                            #
#                           Migrating the state file for the deployer                    #
#                                                                                        #
#                                                                                        #
##########################################################################################
if [ 3 -eq "$step" ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                          $cyan Migrating the deployer state $reset_formatting                               #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	cd "${deployer_dirname}" || exit

	if [ -f .terraform/terraform.tfstate ]; then
		STATE_SUBSCRIPTION=$(grep -m1 "subscription_id" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
		REMOTE_STATE_SA=$(grep -m1 "storage_account_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
		REMOTE_STATE_RG=$(grep -m1 "resource_group_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
	fi

	if [[ -z $REMOTE_STATE_SA ]]; then
		load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
	fi

	if [[ -z $STATE_SUBSCRIPTION ]]; then
		load_config_vars "${deployer_config_information}" "STATE_SUBSCRIPTION"
	fi

	if [[ -z $ARM_SUBSCRIPTION_ID ]]; then
		load_config_vars "${deployer_config_information}" "ARM_SUBSCRIPTION_ID"
	fi

	if [ -z "${REMOTE_STATE_SA}" ]; then
		export step=2
		save_config_var "step" "${deployer_config_information}"
		echo "##vso[task.setprogress value=40;]Progress Indicator"
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                   $bold_red Could not find the SAP Library, please re-run! $reset_formatting                    #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		exit 11

	fi

	TF_VAR_subscription_id="${STATE_SUBSCRIPTION}"
	export TF_VAR_subscription_id

	echo "Calling installer.sh with:          --parameterfile ${deployer_file_parametername} \
  --storageaccountname ${REMOTE_STATE_SA} --state_subscription ${STATE_SUBSCRIPTION} --type sap_deployer ${autoApproveParameter} ${ado_flag}"

	if [ "$ado_flag" == "--ado" ] || [ "$approve" == "--auto-approve" ]; then

		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/installer.sh" \
			--type sap_deployer \
			--parameterfile ${deployer_file_parametername} \
			--storageaccountname "${REMOTE_STATE_SA}" \
			$ado_flag \
			--auto-approve; then
			echo ""
			echo -e "${bold_red}Migrating the Deployer state failed${reset_formatting}"
			step=3
			save_config_var "step" "${deployer_config_information}"
			exit 30
		else
			return_code=0

		fi
	else
		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/installer.sh" \
			--type sap_deployer \
			--parameterfile ${deployer_file_parametername} \
			--storageaccountname "${REMOTE_STATE_SA}"; then
			echo -e "${bold_red}Migrating the Deployer state failed${reset_formatting}"
			step=3
			save_config_var "step" "${deployer_config_information}"
			exit 30
		else
			step=4
			save_config_var "step" "${deployer_config_information}"
			return_code=0
		fi
	fi

	cd "${current_directory}" || exit
	export step=4
	save_config_var "step" "${deployer_config_information}"

fi

unset TF_DATA_DIR
cd "$root_dirname" || exit

load_config_vars "${deployer_config_information}" "keyvault"
load_config_vars "${deployer_config_information}" "deployer_public_ip_address"
load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"

##########################################################################################
#                                                                                        #
#                                      STEP 4                                            #
#                           Migrating the state file for the library                     #
#                                                                                        #
#                                                                                        #
##########################################################################################

if [ 4 -eq $step ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                          $cyan Migrating the library state $reset_formatting                                #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/run/sap_library/
	cd "${library_dirname}" || exit
	if [ -f .terraform/terraform.tfstate ]; then
		STATE_SUBSCRIPTION=$(grep -m1 "subscription_id" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
		REMOTE_STATE_SA=$(grep -m1 "storage_account_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
		REMOTE_STATE_RG=$(grep -m1 "resource_group_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
	fi
	echo "Calling installer.sh with:          \
        --type sap_library \
      --parameterfile ${library_file_parametername} \
      --storageaccountname ${REMOTE_STATE_SA} \
      --deployer_tfstate_key ${deployer_tfstate_key}"

	if [ "$ado_flag" == "--ado" ] || [ "$approve" == "--auto-approve" ]; then

		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/installer.sh" \
			--type sap_library \
			--parameterfile "${library_file_parametername}" \
			--storageaccountname "${REMOTE_STATE_SA}" \
			--deployer_tfstate_key "${deployer_tfstate_key}" \
			$ado_flag \
			--auto-approve; then
			echo "Migrating the SAP Library state failed"
			step=4
			save_config_var "step" "${deployer_config_information}"
			exit 40
		else
			return_code=$?
		fi
	else
		if ! "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/installer.sh" \
			--type sap_library \
			--parameterfile "${library_file_parametername}" \
			--storageaccountname "${REMOTE_STATE_SA}" \
			--deployer_tfstate_key "${deployer_tfstate_key}"; then
			echo "Migrating the SAP Library state failed"
			step=4
			save_config_var "step" "${deployer_config_information}"
			exit 40
		else
			return_code=$?
		fi
	fi

	cd "$root_dirname" || exit

	step=5
	save_config_var "step" "${deployer_config_information}"
fi

printf -v kvname '%-40s' "${keyvault}"
printf -v dep_ip '%-40s' "${deployer_public_ip_address}"
printf -v storage_account '%-40s' "${REMOTE_STATE_SA}"
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "# $cyan Please save these values: $reset_formatting                                                           #"
echo "#     - Key Vault:       ${kvname}                       #"
echo "#     - Deployer IP:     ${dep_ip}                       #"
echo "#     - Storage Account: ${storage_account}                       #"
echo "#                                                                                       #"
echo "#########################################################################################"

now=$(date)
cat <<EOF >"${deployer_config_information}".md
# Control Plane Deployment #

Date : "${now}"

## Configuration details ##

| Item                    | Name                 |
| ----------------------- | -------------------- |
| Environment             | $environment         |
| Location                | $region              |
| Keyvault Name           | ${kvname}            |
| Deployer IP             | ${dep_ip}            |
| Terraform state         | ${storage_account}   |

EOF

cat "${deployer_config_information}".md

deployer_keyvault="${keyvault}"
export deployer_keyvault

if [ -n "${deployer_public_ip_address}" ]; then
	deployer_ip="${deployer_public_ip_address}"
	export deployer_ip
fi

terraform_state_storage_account="${REMOTE_STATE_SA}"
export terraform_state_storage_account

if [ 5 -eq $step ]; then
	if [ "${ado_flag}" != "--ado" ]; then
		cd "${current_directory}" || exit

		load_config_vars "${deployer_config_information}" "sshsecret"
		load_config_vars "${deployer_config_information}" "keyvault"
		load_config_vars "${deployer_config_information}" "deployer_public_ip_address"
		if [ ! -f /etc/profile.d/deploy_server.sh ]; then
			# Only run this when not on deployer
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#                         $cyan  Copying the parameterfiles $reset_formatting                                 #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""

			if [ -n "${sshsecret}" ]; then
				step=3
				save_config_var "step" "${deployer_config_information}"
				printf "%s\n" "Collecting secrets from KV"
				temp_file=$(mktemp)
				ppk=$(az keyvault secret show --vault-name "${keyvault}" --name "${sshsecret}" | jq -r .value)
				echo "${ppk}" >"${temp_file}"
				chmod 600 "${temp_file}"

				remote_deployer_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$deployer_parameter_file")
				remote_library_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$library_parameter_file")
				remote_config_dir="$CONFIG_REPO_PATH/.sap_deployment_automation"

				ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_deployer_dir}"/.terraform 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$deployer_parameter_file" azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/. 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.terraform/terraform.tfstate 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/terraform.tfstate 2>/dev/null

				ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" " mkdir -p ${remote_library_dir}"/.terraform 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/. 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$library_parameter_file" azureadm@"${deployer_public_ip_address}":"$remote_library_dir"/. 2>/dev/null

				ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_config_dir}" 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "${deployer_config_information}" azureadm@"${deployer_public_ip_address}":"${remote_config_dir}"/. 2>/dev/null
				rm "${temp_file}"
			fi
		fi

	fi
fi

step=3
save_config_var "step" "${deployer_config_information}"
echo "##vso[task.setprogress value=100;]Progress Indicator"

unset TF_DATA_DIR

exit 0
