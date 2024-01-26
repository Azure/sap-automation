#!/bin/bash

#error codes include those from /usr/include/sysexits.h

#colors for terminal
boldreduscore="\e[1;4;31m"
boldred="\e[1;31m"
cyan="\e[1;36m"
resetformatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/deploy_utils.sh"

function showhelp {
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: sync_deployer.sh                                                             #"
    echo "#      -o or --storageaccountname      Storage account name for state file              #"
    echo "#      -s or --state_subscription      Subscription for tfstate storage account         #"
    echo "#      -h or --help                    Show help                                        #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/sync_deployer.sh \                                        #"
    echo "#      --storageaccountname mgmtweeutfstate### \                                        #"
    echo "#      --state_subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx                        #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

INPUT_ARGUMENTS=$(getopt -n sync_deployer -o o:s:h --longoptions storageaccountname:,state_subscription:,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
    case "$1" in
        -k | --state_subscription)
            STATE_SUBSCRIPTION="$2"
            shift 2
        ;;
        -o | --storageaccountname)
            REMOTE_STATE_SA="$2"
            shift 2
        ;;
        -h | --help)
            showhelp
            exit 3
            shift
        ;;
        --)
            shift
            break
        ;;
    esac
done

useSAS=$(az storage account show  --name  "${REMOTE_STATE_SA}"   --query allowSharedKeyAccess --out tsv)

if [ $useSAS = "true" ] ; then
  files=$(az storage blob list --container-name tfvars --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --query "[].name" -o tsv --only-show-errors --output tsv)
else
  files=$(az storage blob list --container-name tfvars --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --auth-mode login --query "[].name" -o tsv --only-show-errors --output tsv)
fi
for name in $files;
do
    if [ -n "$name" ] ; then
        echo "Downloading file: " "$name"
        dirName=$(dirname "$name")
        mkdir -p "$dirName"
        if [ $useSAS = "true" ] ; then
          az storage blob download --container-name tfvars --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}"  --file "${name}" --name "${name}" --only-show-errors --output none --no-progress
        else
          az storage blob download --container-name tfvars --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}"  --auth-mode login --file "${name}" --name "${name}" --only-show-errors --output none --no-progress
        fi
    fi

done
