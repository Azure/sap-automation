#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#colors for terminal
bold_red="\e[1;31m"
cyan="\e[1;36m"
reset_formatting="\e[0m"

# if [ -f /etc/profile.d/deploy_server.sh ]; then
# 	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
# 	export PATH=$PATH:$path
# fi

########################################################################################
#                                                                                      #
# Function to Print a Banner                                                           #
# Arguments:                                                                           #
#   $1 - Title of the banner                                                           #
#   $2 - Message to display                                                            #
#   $3 - Type of message (error, success, warning, info)                               #
#   $4 - Secondary message (optional)                                                  #
# Returns:                                                                             #
#   None                                                                               #
########################################################################################
# Example usage:		                                                                   #
#   print_banner "Title" "This is a message" "info" "Secondary message"                #
#   print_banner "Title" "This is a message" "error"                                   #
#   print_banner "Title" "This is a message" "success" "Secondary message"             #
#                                                                                      #
########################################################################################

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

	length=${#secondary_message}
	if ((length % 2 == 0)); then
		secondary_message="$secondary_message "
	else
		secondary_message="$secondary_message"
	fi

	local bold_red="\e[1;31m"
	local cyan="\e[1;36m"
	local green="\e[1;32m"
	local reset="\e[0m"
	local yellow="\e[0;33m"

	local color
	case "$type" in
	error)
		color="$bold_red"
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
	echo "#################################################################################"
	echo -e "${reset}"
	echo ""
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   show_help_installer_v2                                                              #
#                                                                                       #
#########################################################################################

function show_help_installer_v2 {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to deploy the different systems                        #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                      #"
	echo "#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation#"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: installer_v2.sh                                                              #"
	echo "#    -p or --parameter_file              parameter file                                 #"
	echo "#    -t or --type                         type of system to remove                      #"
	echo "#                                         valid options:                                #"
	echo "#                                           sap_deployer                                #"
	echo "#                                           sap_library                                 #"
	echo "#                                           sap_landscape                               #"
	echo "#                                           sap_system                                  #"
	echo "#    -c or --control_plane_name          name of control plane                          #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#                                                                                       #"
	echo "#    -n or --application_configuration_name  Name of Application Configuration          #"
	echo "#    -w or --workload_zone_name              Name of Workload zone                      #"
	echo "#    -o or --storage_accountname             Storage account name for state file        #"
	echo "#    -d or --deployer_tfstate_key            Deployer terraform state file name         #"
	echo "#    -l or --landscape_tfstate_key           Workload zone terraform state file name    #"
	echo "#    -s or --state_subscription              Subscription for terraform storage account #"
	echo "#    -i or --auto-approve                    Silent install                             #"
	echo "#    -h or --help                            Show help                                  #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/installer_v2.sh \                                         #"
	echo "#      --parameter_file DEV-WEEU-SAP01-X00 \                                            #"
	echo "#      --control_plane_name MGMT-WEEO-DEP01 \                                           #"
	echo "#      --type sap_system \                                                              #"
	echo "#      --auto-approve                                                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	return 0
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   show_help_remover_v2                                                                #
#                                                                                       #
#########################################################################################

function show_help_remover_v2 {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to remove the different systems                        #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                      #"
	echo "#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation#"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: remover_v2.sh                                                                #"
	echo "#    -p or --parameter_file              parameter file                                 #"
	echo "#    -t or --type                         type of system to remove                      #"
	echo "#                                         valid options:                                #"
	echo "#                                           sap_deployer                                #"
	echo "#                                           sap_library                                 #"
	echo "#                                           sap_landscape                               #"
	echo "#                                           sap_system                                  #"
	echo "#    -c or --control_plane_name          name of control plane                          #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#                                                                                       #"
	echo "#    -n or --application_configuration_name  Name of Application Configuration          #"
	echo "#    -w or --workload_zone_name              Name of Workload zone                      #"
	echo "#    -o or --storage_accountname             Storage account name for state file        #"
	echo "#    -d or --deployer_tfstate_key            Deployer terraform state file name         #"
	echo "#    -l or --landscape_tfstate_key           Workload zone terraform state file name    #"
	echo "#    -s or --state_subscription              Subscription for terraform storage account #"
	echo "#    -i or --auto-approve                    Silent install                             #"
	echo "#    -h or --help                            Show help                                  #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/remover_v2.sh \                                           #"
	echo "#      --parameter_file DEV-WEEU-SAP01-X00 \                                            #"
	echo "#      --control_plane_name MGMT-WEEO-DEP01 \                                           #"
	echo "#      --type sap_system \                                                              #"
	echo "#      --auto-approve                                                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	return 0
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   control_plane_showhelp                                                              #
#                                                                                       #
#########################################################################################
function control_plane_showhelp {
	echo ""
	echo "#################################################################################################################"
	echo "#                                                                                                               #"
	echo "#                                                                                                               #"
	echo "#   This file contains the logic to deploy the SDAF control plane to an Azure region to support the             #"
	echo "#   SAP Deployment Automation Framework.                                                                        #"
	echo "#   The script experts the following exports:                                                                   #"
	echo "#                                                                                                               #"
	echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                                            #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                                      #"
	echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                                     #"
	echo "#                                                                                                               #"
	echo "#   The script is to be run from a parent folder to the folders containing the json parameter files for         #"
	echo "#    the deployer and the library and the environment.                                                          #"
	echo "#                                                                                                               #"
	echo "#   The script will persist the parameters needed between the executions in the                                 #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                                         #"
	echo "#                                                                                                               #"
	echo "#                                                                                                               #"
	echo "#   Usage: deploy_controlplane.sh                                                                               #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                                            #"
	echo "#      -l or --library_parameter_file        library parameter file                                             #"
	echo "#                                                                                                               #"
	echo "#   Optional parameters                                                                                         #"
	echo "#      -s or --subscription                  subscription                                                       #"
	echo "#      -c or --spn_id                        SPN application id                                                 #"
	echo "#      -p or --spn_secret                    SPN password                                                       #"
	echo "#      -t or --tenant_id                     SPN Tenant id                                                      #"
	echo "#      -f or --force                         Clean up the local Terraform files.                                #"
	echo "#      -i or --auto-approve                  Silent install                                                     #"
	echo "#      -h or --help                          Help                                                               #"
	echo "#                                                                                                               #"
	echo "#   Example:                                                                                                    #"
	echo "#                                                                                                               #"
	echo "#  \$SAP_AUTOMATION_REPO_PATH/scripts/deploy_controlplane.sh \                                                   #"
	echo "#      --deployer_parameter_file DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json \  #"
	echo "#      --library_parameter_file LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json \                      #"
	echo "#                                                                                                               #"
	echo "#   Example:                                                                                                    #"
	echo "#                                                                                                               #"
	echo "#   \$SAP_AUTOMATION_REPO_PATH/scripts/deploy_controlplane.sh \                                                  #"
	echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json  \ #"
	echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                      #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                                    #"
	echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                                          #"
	echo "#      --spn_secret ************************ \                                                                  #"
	echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                                                       #"
	echo "#      --auto-approve                                                                                           #"
	echo "#                                                                                                               #"
	echo "#################################################################################################################"
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   control_plane_show_help_v2                                                          #
#                                                                                       #
#########################################################################################
function control_plane_show_help_v2 {
	echo ""
	echo "###################################################################################################################"
	echo "#                                                                                                                 #"
	echo "#                                                                                                                 #"
	echo "#   This file contains the logic to deploy the SDAF control plane to an Azure region to support the               #"
	echo "#   SAP Deployment Automation Framework.                                                                          #"
	echo "#   The script experts the following exports:                                                                     #"
	echo "#                                                                                                                 #"
	echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                                              #"
	echo "#     SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                                         #"
	echo "#     CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                                        #"
	echo "#                                                                                                                 #"
	echo "#   The script is to be run from a parent folder to the folders containing the parameter files for                #"
	echo "#    the deployer and the library and the environment.                                                            #"
	echo "#                                                                                                                 #"
	echo "#   The script will persist the parameters needed between the executions in the                                   #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                          #"
	echo "#                                                                                                                 #"
	echo "#                                                                                                                 #"
	echo "#   Usage: deploy_control_plane_v2.sh                                                                             #"
	echo "#      -c or --control_plane_name            control plane name file                                              #"
	echo "#                                                                                                                 #"
	echo "#   Usage: deploy_control_plane_v2.sh                                                                             #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                                              #"
	echo "#      -l or --library_parameter_file        library parameter file                                               #"
	echo "#                                                                                                                 #"
	echo "#   Optional parameters                                                                                           #"
	echo "#      -s or --subscription                   subscription                                                        #"
	echo "#      -t or --terraform_storage_account_name terraform state file storage account name                           #"
	echo "#      -v or --vault                          name of key vault for deployment credentials                        #"
	echo "#      -m or --msi                            control plane uses managed identity                                 #"
	echo "#      -o or --only_deployer                  bootstraps the deployer and terminates                              #"
	echo "#      -f or --force                          reinstalls the control plane                                        #"
	echo "#      -v or --ado                            is being called from Azure DevOps.                                  #"
	echo "#      -i or --auto-approve                   silent install                                                      #"
	echo "#      -h or --help                           Help                                                                #"
	echo "#                                                                                                                 #"
	echo "#   Example:                                                                                                      #"
	echo "#                                                                                                                 #"
	echo "#  \$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_control_plane_v2.sh \                                          #"
	echo "#      --control_plane_name MGMT-WEEU-DEP01                                                                       #"
	echo "#                                                                                                                 #"
	echo "#   Example:                                                                                                      #"
	echo "#                                                                                                                 #"
	echo "#  \$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_control_plane_v2.sh \                                          #"
	echo "#      --deployer_parameter_file DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.tfvars \  #"
	echo "#      --library_parameter_file LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.tfvars \                      #"
	echo "#                                                                                                                 #"
	echo "#   Example:                                                                                                      #"
	echo "#                                                                                                                 #"
	echo "#   \$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh \                                             #"
	echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.tfvars \  #"
	echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.tfvars \                      #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                                      #"
	echo "#      --auto-approve                                                                                             #"
	echo "#                                                                                                                 #"
	echo "###################################################################################################################"
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   remove_control_plane_show_help_v2                                                   #
#                                                                                       #
#########################################################################################

function remove_control_plane_show_help_v2 {
	echo ""
	echo "###################################################################################################################"
	echo "#                                                                                                                 #"
	echo "#                                                                                                                 #"
	echo "#   This file contains the logic to deploy the SDAF control plane to an Azure region to support the               #"
	echo "#   SAP Deployment Automation Framework.                                                                          #"
	echo "#   The script experts the following exports:                                                                     #"
	echo "#                                                                                                                 #"
	echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                                              #"
	echo "#     SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                                         #"
	echo "#     CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                                        #"
	echo "#                                                                                                                 #"
	echo "#   The script is to be run from a parent folder to the folders containing the parameter files for                #"
	echo "#    the deployer and the library and the environment.                                                            #"
	echo "#                                                                                                                 #"
	echo "#   The script will persist the parameters needed between the executions in the                                   #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                          #"
	echo "#                                                                                                                 #"
	echo "#                                                                                                                 #"
	echo "#   Usage: remove_control_plane_v2.sh                                                                             #"
	echo "#      -c or --control_plane_name            control plane name file                                              #"
	echo "#                                                                                                                 #"
	echo "#   Usage: remove_control_plane_v2.sh                                                                             #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                                              #"
	echo "#      -l or --library_parameter_file        library parameter file                                               #"
	echo "#                                                                                                                 #"
	echo "#   Optional parameters                                                                                           #"
	echo "#      -s or --subscription                   subscription                                                        #"
	echo "#      -t or --terraform_storage_account_name terraform state file storage account name                           #"
	echo "#      -v or --vault                          name of key vault for deployment credentials                        #"
	echo "#      -m or --msi                            control plane uses managed identity                                 #"
	echo "#      -o or --only_deployer                  bootstraps the deployer and terminates                              #"
	echo "#      -f or --force                          reinstalls the control plane                                        #"
	echo "#      -v or --ado                            is being called from Azure DevOps.                                  #"
	echo "#      -i or --auto-approve                   silent install                                                      #"
	echo "#      -h or --help                           Help                                                                #"
	echo "#                                                                                                                 #"
	echo "#   Example:                                                                                                      #"
	echo "#                                                                                                                 #"
	echo "#  \$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_control_plane_v2.sh \                                          #"
	echo "#      --control_plane_name MGMT-WEEU-DEP01                                                                       #"
	echo "#                                                                                                                 #"
	echo "#   Example:                                                                                                      #"
	echo "#                                                                                                                 #"
	echo "#  \$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_control_plane_v2.sh \                                          #"
	echo "#      --deployer_parameter_file DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.tfvars \  #"
	echo "#      --library_parameter_file LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.tfvars \                      #"
	echo "#                                                                                                                 #"
	echo "#   Example:                                                                                                      #"
	echo "#                                                                                                                 #"
	echo "#   \$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_control_plane_v2.sh \                                         #"
	echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.tfvars \  #"
	echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.tfvars \                      #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                                      #"
	echo "#      --auto-approve                                                                                             #"
	echo "#                                                                                                                 #"
	echo "###################################################################################################################"
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   Missing parameter                                                                   #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   control_plane_missing "Environment"                                                 #
#                                                                                       #
#########################################################################################

function control_plane_missing {
	printf -v val '%-40s' "$1"
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing : ${val}                                  #"
	echo "#                                                                                       #"
	echo "#   Usage: deploy_controlplane.sh                                                       #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                    #"
	echo "#      -l or --library_parameter_file        library parameter file                     #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#      -s or --subscription                  subscription                               #"
	echo "#      -c or --spn_id                        SPN application id                         #"
	echo "#      -p or --spn_secret                    SPN password                               #"
	echo "#      -t or --tenant_id                     SPN Tenant id                              #"
	echo "#      -f or --force                         Clean up the local Terraform files.        #"
	echo "#      -i or --auto-approve                  Silent install                             #"
	echo "#      -h or --help                          Help                                       #"
	echo "#                                                                                       #"
	echo "#########################################################################################"

}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   Missing parameter                                                                   #
#   Script name                                                                         #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   control_plane_missing_v2 "Environment" "control_plane_missing_v2"                   #
#                                                                                       #
#########################################################################################

function control_plane_missing_v2 {
	printf -v val '%-40s' "$1"
	printf -v val2 '%-42s' "$2"

	echo ""
	echo "################################################################################################"
	echo "#                                                                                              #"
	echo "#   Missing : ${val}                                         #"
	echo "#                                                                                              #"
	echo "#   Usage:  ${val2}                                         #"
	echo "#      -c or --control_plane_name            control plane name file                           #"
	echo "#                                                                                              #"
	echo "#   Usage:  ${val2}                                         #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                           #"
	echo "#      -l or --library_parameter_file        library parameter file                            #"
	echo "#                                                                                              #"
	echo "#   Optional parameters                                                                        #"
	echo "#      -s or --subscription                   subscription                                     #"
	echo "#      -t or --terraform_storage_account_name terraform state file storage account name        #"
	echo "#      -v or --vault                          name of key vault for deployment credentials     #"
	echo "#      -m or --msi                            control plane uses managed identity              #"
	echo "#      -o or --only_deployer                  bootstraps the deployer and terminates           #"
	echo "#      -f or --force                          reinstalls the control plane                     #"
	echo "#      -v or --ado                            is being called from Azure DevOps.               #"
	echo "#      -i or --auto-approve                   silent install                                   #"
	echo "#      -h or --help                           Help                                             #"
	echo "#                                                                                              #"
	echo "################################################################################################"

}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   workload_zone_showhelp                                                              #
#                                                                                       #
#########################################################################################

function workload_zone_showhelp {
	echo ""
	echo "###############################################################################################"
	echo "#                                                                                             #"
	echo "#                                                                                             #"
	echo "#   This file contains the logic to deploy the workload infrastructure to Azure               #"
	echo "#                                                                                             #"
	echo "#   The script experts the following exports:                                                 #"
	echo "#                                                                                             #"
	echo "#   SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                       #"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                      #"
	echo "#                                                                                             #"
	echo "#   The script is to be run from the folder containing the json parameter file                #"
	echo "#                                                                                             #"
	echo "#   The script will persist the parameters needed between the executions in the               #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                       #"
	echo "#                                                                                             #"
	echo "#   Usage: install_workloadzone.sh                                                            #"
	echo "#      -p or --parameterfile                deployer parameter file                           #"
	echo "#                                                                                             #"
	echo "#   Optional parameters                                                                       #"
	echo "#      -d or --deployer_tfstate_key          Deployer terraform state file name               #"
	echo "#      -e or --deployer_environment          Deployer environment, i.e. MGMT                  #"
	echo "#      -s or --subscription                  subscription                                     #"
	echo "#      -k or --state_subscription            subscription for statefile                       #"
	echo "#      -c or --spn_id                        SPN application id                               #"
	echo "#      -p or --spn_secret                    SPN password                                     #"
	echo "#      -t or --tenant_id                     SPN Tenant id                                    #"
	echo "#      -f or --force                         Clean up the local Terraform files.              #"
	echo "#      -i or --auto-approve                  Silent install                                   #"
	echo "#      -h or --help                          Help                                             #"
	echo "#                                                                                             #"
	echo "#   Example:                                                                                  #"
	echo "#                                                                                             #"
	echo "#   [REPO-ROOT]deploy/scripts/install_workloadzone.sh \                                       #"
	echo "#      --parameterfile PROD-WEEU-SAP01-INFRASTRUCTURE                                         #"
	echo "#                                                                                             #"
	echo "#   Example:                                                                                  #"
	echo "#                                                                                             #"
	echo "#   [REPO-ROOT]deploy/scripts/install_workloadzone.sh \                                       #"
	echo "#      --parameterfile PROD-WEEU-SAP01-INFRASTRUCTURE \                                       #"
	echo "#      --deployer_environment MGMT \                                                          #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                  #"
	echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                        #"
	echo "#      --spn_secret ************************ \                                                #"
	echo "#      --spn_secret yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                    #"
	echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                                     #"
	echo "#      --auto-approve                                                                         #"
	echo "##############################################################################################"
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   Missing parameter                                                                   #
# Returns:                                                                              #
#   None                                                                                #
# Example usage:                                                                        #
#   workload_zone_missing "Environment"                                                 #
#                                                                                       #
#########################################################################################

function workload_zone_missing {
	printf -v val %-.40s "$1"
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables: ${val}!!!              #"
	echo "#                                                                                       #"
	echo "#   Please export the folloing variables:                                               #"
	echo "#   SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                 #"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
	echo "#                                                                                       #"
	echo "#   Usage: install_workloadzone.sh                                                      #"
	echo "#      -p or --parameterfile                deployer parameter file                     #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#      -d or --deployer_tfstate_key          Deployer terraform state file name         #"
	echo "#      -e or --deployer_environment          Deployer environment, i.e. MGMT            #"
	echo "#      -k or --state_subscription            subscription of keyvault with SPN details  #"
	echo "#      -v or --keyvault                      Name of Azure keyvault with SPN details    #"
	echo "#      -s or --subscription                  subscription                               #"
	echo "#      -c or --spn_id                        SPN application id                         #"
	echo "#      -o or --storageaccountname            Storage account for terraform state files  #"
	echo "#      -n or --spn_secret                    SPN password                               #"
	echo "#      -t or --tenant_id                     SPN Tenant id                              #"
	echo "#      -f or --force                         Clean up the local Terraform files.        #"
	echo "#      -i or --auto-approve                  Silent install                             #"
	echo "#      -h or --help                          Help                                       #"
	echo "#########################################################################################"
}

#########################################################################################
#                                                                                       #
# Function to validate the exports needed for the script                                #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   0 - Success                                                                         #
#   65 - Missing environment variables                                                  #
# Example usage:                                                                        #
#   validate_exports                                                                    #
#                                                                                       #
#########################################################################################

function validate_exports {
	if [ -z "$SAP_AUTOMATION_REPO_PATH" ]; then
		echo ""
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#  $bold_red Missing environment variables (SAP_AUTOMATION_REPO_PATH)!!! $reset_formatting                            #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables:                                              #"
		echo "#      SAP_AUTOMATION_REPO_PATH (path to the automation repo folder (sap-automation))   #"
		echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
		echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	if [ -z "$CONFIG_REPO_PATH" ]; then
		echo ""
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#  $bold_red Missing environment variables (CONFIG_REPO_PATH)!!! $reset_formatting                            #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables:                                              #"
		echo "#      CONFIG_REPO_PATH (path to the repo folder (sap-automation))                      #"
		echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
		echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#  $bold_red Missing environment variables (ARM_SUBSCRIPTION_ID)!!! $reset_formatting  #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables:                                              #"
		echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
		echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
		echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	return 0
}

#########################################################################################
#                                                                                       #
# Function to validate the WEb App exports needed for the script                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   0 - Success                                                                         #
#   65 - Missing environment variables                                                  #
# Example usage:                                                                        #
#   validate_webapp_exports                                                             #
#                                                                                       #
#########################################################################################

function validate_webapp_exports {
	if [ -z "$TF_VAR_app_registration_app_id" ]; then
		echo ""
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#        $bold_red Missing environment variables (TF_VAR_app_registration_app_id)!!! $reset_formatting            #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables to successfully deploy the Webapp:            #"
		echo "#      TF_VAR_app_registration_app_id (webapp registration application id)              #"
		echo "#      TF_VAR_webapp_client_secret (webapp registration password / secret)              #"
		echo "#                                                                                       #"
		echo "#   If you do not wish to deploy the Webapp, unset the TF_VAR_use_webapp variable       #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	if [ "${ARM_USE_MSI}" == "false" ]; then
		if [ -z "$TF_VAR_webapp_client_secret" ]; then
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#            $bold_red Missing environment variables (TF_VAR_webapp_client_secret)!!! $reset_formatting           #"
			echo "#                                                                                       #"
			echo "#   Please export the following variables to successfully deploy the Webapp:            #"
			echo "#      TF_VAR_app_registration_app_id (webapp registration application id)              #"
			echo "#      TF_VAR_webapp_client_secret (webapp registration password / secret)              #"
			echo "#                                                                                       #"
			echo "#   If you do not wish to deploy the Webapp, unset the TF_VAR_use_webapp variable       #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			return 65 #data format error
		fi
	fi

	return 0
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   None                                                                                #
#########################################################################################
# Example usage:                                                                        #
#   show_help                                                                           #
#                                                                                       #
#########################################################################################

function showhelp {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to deploy the different systems                        #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                      #"
	echo "#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation#"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                 #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: installer.sh                                                                 #"
	echo "#    -p or --parameterfile           parameter file                                     #"
	echo "#    -t or --type                         type of system to remove                      #"
	echo "#                                         valid options:                                #"
	echo "#                                           sap_deployer                                #"
	echo "#                                           sap_library                                 #"
	echo "#                                           sap_landscape                               #"
	echo "#                                           sap_system                                  #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#                                                                                       #"
	echo "#    -o or --storageaccountname      Storage account name for state file                #"
	echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
	echo "#    -i or --auto-approve            Silent install                                     #"
	echo "#    -h or --help                    Show help                                          #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
	echo "#      --parameterfile DEV-WEEU-SAP01-X00 \                                             #"
	echo "#      --type sap_system                                                                #"
	echo "#      --auto-approve                                                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

#########################################################################################
#                                                                                       #
# Function to show help for the installer script                                        #
# Arguments:                                                                            #
#   Missing parameter                                                                   #
# Returns:                                                                              #
#   None                                                                                #
# Example usage:                                                                        #
#   missing "Environment"                                                               #
#                                                                                       #
#########################################################################################

function missing {
	printf -v val %-.40s "$option"
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables: ${option}!!!              #"
	echo "#                                                                                       #"
	echo "#   Please export the folloing variables:                                               #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
	echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)             #"
	echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
	echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
	echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

#########################################################################################
#                                                                                       #
# Function to validate the dependencies needed for the script                           #
# Arguments:                                                                            #
#   None                                                                                #
# Returns:                                                                              #
#   0 - Success                                                                         #
#   2 - Terraform not found                                                             #
#   64 - Incorrect parameter file                                                       #
#   65 - Missing environment variables                                                  #
# Example usage:                                                                        #
#   validate_dependencies                                                               #
#                                                                                       #
#########################################################################################

function validate_dependencies {
	tfPath="/opt/terraform/bin/terraform"

	if [ -f /opt/terraform/bin/terraform ]; then
		tfPath="/opt/terraform/bin/terraform"
	else
		tfPath=$(which terraform)
	fi

	echo "Checking Terraform:                  $tfPath"

	# if /opt/terraform exists, assign permissions to the user
	if [ -d /opt/terraform ]; then
		current_owner=$(stat /opt/terraform --format %U)
		if [ "$current_owner" != "$USER" ]; then
			print_banner "Installer" "Changing ownership of /opt/terraform to $USER" "info"
			# Change ownership to the current user
			sudo chown -R "$USER" /opt/terraform
		fi
	fi

	# Check terraform
	if checkIfCloudShell; then
		tf=$(terraform --version | grep Terraform)
	else
		tf=$($tfPath --version | grep Terraform)
	fi

	if [ -z "$tf" ]; then
		print_banner "Installer" "Terraform not found" "error"
		return 2 #No such file or directory
	fi

	if checkIfCloudShell; then
		mkdir -p "${HOME}/.terraform.d/plugin-cache"
		export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"
	else
		if [ ! -d "/opt/terraform/.terraform.d/plugin-cache" ]; then
			mkdir -p "/opt/terraform/.terraform.d/plugin-cache"
		fi
		export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache
	fi
	# Set Terraform Plug in cache

	az_version=$(az --version | grep "azure-cli")
	if [ -z "${az_version}" ]; then
		print_banner "Installer" "Azure CLI not found" "error"
		return 2 #No such file or directory
	fi
	cloudIDUsed=$(az account show | grep "cloudShellID" || true)
	if [ -n "${cloudIDUsed}" ]; then
		print_banner "Installer" "Please login using your credentials or service principal credentials" "error"
		exit 67 #addressee unknown
	fi

	return 0
}

################################################################################
#                                                                              #
# Function to validate the key parameters needed for the script                #
# Arguments:                                                                   #
#   $1 - The name of the parameter file to validate                            #
# Returns:                                                                     #
#   0 - Success                                                                #
#   64 - Incorrect parameter file                                              #
#                                                                              #
################################################################################

function validate_key_parameters {
	echo "Validating:                          $1"

	# Helper variables
	load_config_vars "$1" "environment"
	environment=$(echo "${environment}" | xargs | tr "[:lower:]" "[:upper:]" | tr -d '\r')
	export environment

	if [ -z "${environment}" ]; then
		print_banner "Installer" "Incorrect parameter file" "error" "The file must contain the environment attribute"
		return 64 #script usage wrong
	fi

	load_config_vars "$1" "location"
	region=$(echo "${location}" | xargs | tr -d '\r')
	export region

	if [ -z "${region}" ]; then
		print_banner "Installer" "Incorrect parameter file" "error" "The file must contain the location attribute"
		return 64 #script usage wrong
	fi

	load_config_vars "$1" "management_network_logical_name"
	export management_network_logical_name

	load_config_vars "$1" "network_logical_name"
	export network_logical_name

	return 0
}

#####################################################################################
#                                                                                   #
# Function to compare two version numbers                                           #
# Arguments:                                                                        #
#   $1 - The first version number to compare                                        #
#   $2 - The second version number to compare                                       #
# Returns:                                                                          #
#   0 - The first version is equal to the second version                            #
#   1 - The first version is greater than the second version                        #
#   2 - The first version is less than the second version                           #
#                                                                                   #
# Example usage:                                                                    #
#   version_compare "1.0.0" "1.0.1"                                                 #
#   version_compare "1.0.1" "1.0.0"                                                 #
#                                                                                   #
#####################################################################################

function version_compare {
	echo "Comparison:                          $1 <= $2"

	if [ -z $1 ]; then
		return 2
	fi

	if [[ "$1" == "$2" ]]; then
		return 0
	fi
	local IFS=.
	local i ver1=($1) ver2=($2)
	# fill empty fields in ver1 with zeros
	for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
		ver1[i]=0
	done
	for ((i = 0; i < ${#ver1[@]}; i++)); do
		if ((10#${ver1[i]:=0} > 10#${ver2[i]:=0})); then
			return 1
		fi
		if ((10#${ver1[i]} < 10#${ver2[i]})); then
			return 2
		fi
	done
	return 0
}

#####################################################################################
#                                                                                   #
# Function to replace the resource ID in the state file                             #
# Arguments:                                                                        #
#   $1 - The module ID of the resource to replace                                   #
#   $2 - The directory of the Terraform module                                      #
#   $3 - The resource type to replace                                               #
#   $4 - The import parameters to use for the import command                        #
# Returns:                                                                          #
#   0 - Success                                                                     #
#   1 - Failure                                                                     #
#                                                                                   #
#####################################################################################

function ReplaceResourceInStateFile {

	local moduleID=$1
	local terraform_module_directory=$2

	# shellcheck disable=SC2086
	if [ -z $STORAGE_ACCOUNT_ID ]; then
		azureResourceID=$(terraform -chdir="${terraform_module_directory}" state show "${moduleID}" | grep -m1 $3 | xargs | cut -d "=" -f2 | xargs)
		tempString=$(echo "${azureResourceID}" | grep "/fileshares/")
		if [ -n "${tempString}" ]; then
			# Use sed to replace /fileshares/ with /shares/
			# shellcheck disable=SC2001
			azureResourceID=$(echo "$azureResourceID" | sed 's|/fileshares/|/shares/|g')
		fi
	else
		azureResourceID=$STORAGE_ACCOUNT_ID
	fi

	echo "Terraform resource ID:  $moduleID"
	echo "Azure resource ID:      $azureResourceID"
	if [ -n "${azureResourceID}" ]; then
		echo "Removing storage account state object:           ${moduleID} "
		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
			echo "Importing storage account state object:           ${moduleID}"
			echo "terraform -chdir=${terraform_module_directory} import -var-file=${var_file} -var deployer_tfstate_key=${deployer_tfstate_key} -var tfstate_resource_id=${tfstate_resource_id} $4 ${moduleID} ${azureResourceID}"
			echo ""
			if ! terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" -var "deployer_tfstate_key=${deployer_tfstate_key}" -var "tfstate_resource_id=${tfstate_resource_id}" $4 "${moduleID}" "${azureResourceID}"; then
				echo -e "$bold_red Importing storage account state object:           ${moduleID} failed $reset_formatting"
				exit 65
			fi
		fi
	fi

	return $?
}

####################################################################################
# Function to import resources and re-run apply                                    #
# This function is used to import resources that already exist in Azure            #
# and re-run the apply command to ensure that the state file is updated            #
# with the correct resource IDs.                                                   #
# It checks for errors in the Terraform plan and apply output                      #
# and handles them accordingly.                                                    #
# It also checks for resources that can be imported and attempts to import them.	 #
# Arguments:                                                                       #
#   $1 - The name of the file to check for errors in the Terraform output.         #
#   $2 - The directory of the Terraform module.                                    #
#   $3 - The import parameters to use for the import command.                      #
#   $4 - The apply parameters to use for the apply command.                        #
# Returns:                                                                         #
#   0 - Success, no errors found.                                                  #
#   1 - Errors found during the apply phase.                                       #
####################################################################################

function ImportAndReRunApply {
	local fileName=$1
	local terraform_module_directory=$2
	local importParameters=$3
	local applyParameters=$4

	local import_return_value
	import_return_value=0
	local msi_error_count=0
	local error_count=0

	print_banner "ImportAndReRunApply" "In function ImportAndReRunApply" "info"
	# echo "Import parameters: ${importParameters[*]}"
	# echo "Apply parameters: ${applyParameters[*]}"

	if [ -f "$fileName" ]; then
		retry_errors_temp=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary} | select(.summary | contains("A retryable error occurred."))' "$fileName")
		if [[ -n "${retry_errors_temp}" ]]; then
		  rm "$fileName"
			sleep 30
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" apply -no-color -compact-warnings -json -input=false --auto-approve $applyParameters | tee "$fileName"; then
				import_return_value=${PIPESTATUS[0]}
			else
				import_return_value=${PIPESTATUS[0]}
			fi
		fi
	fi
	if [ -f "$fileName" ]; then

		errors_occurred=$(jq 'select(."@level" == "error") | length' "$fileName")

		if [[ -n $errors_occurred ]]; then

			msi_errors_temp=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary} | select(.summary | contains("The role assignment already exists."))' "$fileName")
			if [[ -n "${msi_errors_temp}" ]]; then
				readarray -t msi_errors < <(echo "${msi_errors_temp}" | jq -c '.')
				msi_error_count=${#msi_errors[@]}
			fi

			errors_temp=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary} ' "$fileName")
			if [[ -n "${errors_temp}" ]]; then
				readarray -t errors < <(echo "${errors_temp}" | jq -c '.')
				error_count=${#errors[@]}
			fi
			if [[ "${error_count}" -gt 0 ]]; then
				print_banner "Installer" "Number of errors: $error_count" "error" "Number of permission errors: $msi_error_count"
			else
				print_banner "Installer" "Number of permission errors: $msi_error_count - can safely be ignored" "info"
			fi
			# Check for resource that can be imported
			existing=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary} | select(.summary | startswith("A resource with the ID"))' "$fileName")

			if [[ -n $existing ]]; then
				readarray -t errors < <(echo "${existing}" | jq -c '.')

				for item in "${errors[@]}"; do
					moduleID=$(jq -c -r '.address ' <<<"$item")
					azureResourceID=$(jq -c -r '.summary' <<<"$item" | awk -F'\"' '{print $2}')
					echo "Trying to import $azureResourceID into $moduleID"
					# shellcheck disable=SC2086
					echo terraform -chdir="${terraform_module_directory}" import $importParameters "${moduleID}" "${azureResourceID}"
					echo ""
					# shellcheck disable=SC2086
					if terraform -chdir="${terraform_module_directory}" import $importParameters "${moduleID}" "${azureResourceID}"; then
						import_return_value=$?
					else
						import_return_value=$?
						if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
							if terraform -chdir="${terraform_module_directory}" import $importParameters "${moduleID}" "${azureResourceID}"; then
								import_return_value=$?
							else
								import_return_value=$?
							fi
						fi
					fi
				done

				rm "$fileName"
				# shellcheck disable=SC2086
				if terraform -chdir="${terraform_module_directory}" plan -input=false $importParameters; then
					import_return_value=$?
					print_banner "Installer" "Terraform plan succeeded" "success"
				else
					import_return_value=$?
					print_banner "Installer" "Terraform plan failed" "error"
				fi

				if [ $import_return_value -ne 1 ]; then

					print_banner "Installer" "Re-running Terraform apply after import" "info"
					error_count=0

					# shellcheck disable=SC2086
					if terraform -chdir="${terraform_module_directory}" apply -no-color -compact-warnings -json -input=false --auto-approve $applyParameters | tee "$fileName"; then
						import_return_value=${PIPESTATUS[0]}
					else
						import_return_value=${PIPESTATUS[0]}
					fi
					# shellcheck disable=SC2086
					if [ 1 == $import_return_value ]; then
						print_banner "Installer" "Errors during the apply phase after importing resources" "error"
					else
						# return code 2 is ok
						print_banner "Installer" "Terraform apply succeeded" "success"
						if [ -f "$fileName" ]; then
							rm "$fileName"
						fi
						import_return_value=0
					fi
				fi
			else
				current_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary}' "$fileName")

				if [[ -n $current_errors ]]; then
					import_return_value=0
					echo -e "$bold_red Errors occurred during the apply phase:$reset"
					echo -e "$bold_red ------------------------------------------------------------------------------------- $reset"
					readarray -t errors < <(echo "${current_errors}" | jq -c '.')

					for item in "${errors[@]}"; do
						errorMessage=$(jq -c -r '.summary ' <<<"$item")
						echo "Error: $errorMessage"
						echo "##vso[task.logissue type=error]Error: $errorMessage"
					done
				fi

				if [ -f "$fileName" ]; then
					rm "$fileName"
				fi

			fi
			if [ -f "$fileName" ]; then
				current_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary}' "$fileName")

				if [[ -n $current_errors ]]; then

					echo -e "$bold_red Errors occurred during the apply phase:$reset"
					echo -e "$bold_red ------------------------------------------------------------------------------------- $reset"
					readarray -t errors < <(echo "${current_errors}" | jq -c '.')
					error_count=${#errors[@]}

					for item in "${errors[@]}"; do
						errorMessage=$(jq -c -r '.summary ' <<<"$item")
						echo "Error: $errorMessage"
						echo "##vso[task.logissue type=error]Error: $errorMessage"
					done
				else
					print_banner "ImportAndReRunApply" "No errors" "info"
					if [ -f "$fileName" ]; then
						rm "$fileName"
					fi
					import_return_value=0
				fi

			fi
		else
			print_banner "ImportAndReRunApply" "No errors" "info"
			if [ -f "$fileName" ]; then
				rm "$fileName"
			fi
			import_return_value=0
		fi

	fi
	if [ "$import_return_value" -ne 0 ]; then
		print_banner "ImportAndReRunApply" "Terraform apply failed with return code: $import_return_value" "error"
		echo "##vso[task.logissue type=error]Terraform apply failed with return code: $import_return_value"
	else
		if [ "$error_count" -gt 0 ]; then

			if [ "$error_count" -gt "$msi_error_count" ]; then
				print_banner "ImportAndReRunApply" "Errors occurred during the apply phase" "error"
				echo "##vso[task.logissue type=error]Errors occurred during the apply phase"
				import_return_value=5
			else
				import_return_value=0
			fi
		else
			import_return_value=0
		fi
	fi
	print_banner "ImportAndReRunApply" "Exiting function ImportAndReRunApply" "info" "return code: $import_return_value"

	#shellcheck disable=SC2086
	return $import_return_value
}

########################################################################################
# Function to check if a resource would be recreated in the Terraform plan output.     #
# This function is used to check if a resource would be recreated in the Terraform     #
# plan output. It checks for the presence of the string "must be replaced" in the      #
# Terraform plan output. If the string is found, it indicates that the resource would  #
# be recreated. The function returns 0 if the resource would be recreated, and 1 if it #
# would not.                                                                           #
# Arguments:                                                                           #
#   $1 - The module ID of the resource to check.                                       #
#   $2 - The name of the file to check for the presence of the string.                 #
#   $3 - The short name of the resource.                                               #
# Returns:                                                                             #
#   0 - The resource would be recreated.                                               #
#   1 - The resource would not be recreated.                                           #
########################################################################################

function testIfResourceWouldBeRecreated {
	local moduleId="$1"
	local fileName="$2"
	local shortName="$3"
	printf -v val '%-40s' "$shortName"
	return_value=0
	# || true suppresses the exitcode of grep. To not trigger the strict exit on error
	willResourceWouldBeRecreated=$(grep "$moduleId" "$fileName" | grep -m1 "must be replaced" || true)
	if [ -n "${willResourceWouldBeRecreated}" ]; then
		print_banner "Installer" "Risk for dataloss" "error" "${val} will be removed"
		echo "##vso[task.logissue type=error]Resource will be removed: $shortName"
		return_value=1
	fi
	return $return_value
}

###########################################################################################
# Function to validate the key vault access.                                              #
# This function checks if the key vault exists and if the user has access to it.          #
# It uses the Azure CLI to check for the key vault and its access policies.               #
# If the key vault does not exist or the user does not have access, it will retry         #
# after 60 seconds. If the key vault is still not accessible, it will exit with an error  #
# code. If the user has access, it will return 0.                                         #
# Arguments:                                                                              #
#   $1 - The name of the key vault to check.                                              #
#   $2 - The subscription ID to check the key vault in.                                   #
# Returns:                                                                                #
#   0 - The key vault exists and the user has access.                                     #
#   10 - The key vault does not exist or the user does not have access.                   #
###########################################################################################

function validate_key_vault {
	local keyvault_to_check=$1
	local subscription=$2
	return_value=0

	kv_name_check=$(az keyvault show --name="$keyvault_to_check" --subscription "${subscription}" --query name)
	return_value=$?
	if [ -z "$kv_name_check" ]; then
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                             $cyan  Retrying keyvault access $reset_formatting                               #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		sleep 60
		kv_name_check=$(az keyvault show --name="$keyvault_to_check" --subscription "${subscription}" --query name)
		return_value=$?
	fi

	if [ -z "$kv_name_check" ]; then
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                               $bold_red  Unable to access keyvault: $keyvault_to_check $reset_formatting                            #"
		echo "#                             Please ensure the key vault exists.                       #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		exit 10
	fi

	access_error=$(az keyvault secret list --vault "$keyvault_to_check" --subscription "${subscription}" --only-show-errors | grep "The user, group or application" || true)
	if [ -n "${access_error}" ]; then

		az_subscription_id=$(az account show --query id -o tsv)
		printf -v val %-40.40s "$az_subscription_id"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#$bold_red User account ${val} does not have access to: $keyvault  $reset_formatting"
		echo "#                                                                                       #"
		echo "#########################################################################################"

		echo "##vso[task.setprogress value=40;]Progress Indicator"
		return 65

	fi
	return $return_value

}
############################################################################################
#                                                                                          #
# Function to log on to Azure using either a service principal or managed service identity #
# This function checks if the ARM_USE_MSI environment variable is set to true. If it is,   #
# it uses managed service identity to log on to Azure. If it is not, it uses a service     #
# principal to log on to Azure. It also sets the TF_VAR_use_spn variable to true or false  #
# depending on the authentication method used. It also checks if the ARM_SUBSCRIPTION_ID   #
# environment variable is set to the correct subscription ID. If it is not, it updates     #
# the ARM_SUBSCRIPTION_ID environment variable to the correct subscription ID.             #
# Arguments:                                                                               #
#   $1 - The value of the ARM_USE_MSI environment variable.                                #
# Returns:                                                                                 #
#   0 - Success, logged on to Azure.                                                       #
#   1 - Failure, unable to log on to Azure.                                                #
#                                                                                          #
#############################################################################################

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

################################################################################
# Function to get the Terraform output value for a given output name           #
#                                                                              #
# This function retrieves the value of a Terraform output variable by its name.#
# If the output variable is not found, it returns a default value if provided. #
# If no default value is provided, it returns an empty string.                 #
# It suppresses warnings by redirecting stderr to /dev/null.                   #
# Arguments:                                                                   #
#   $1 - The name of the Terraform output variable to retrieve                 #
#   $2 - Optional default value to return if the output variable is not found	 #
# Returns:                                                                     #
#   The value of the Terraform output variable, or a default value if not found#
################################################################################
# Example usage:                                                               #
#   my_var=$(get_terraform_output "my_output_name" "default_value")            #
#   echo "Variable value: $my_var"                                             #
################################################################################
function get_terraform_output() {
	local output_name="$1"
	local terraform_module_directory="${2:-.}" # Default to current directory if not provided
	local default_value="${3:-}"

	# Try to get the output, suppress warnings
	local value
	if value=$(terraform -chdir="$terraform_module_directory" output -no-color -raw "$output_name" 2>/dev/null); then
		echo "$value"
	else
		echo "$default_value"
	fi
}
