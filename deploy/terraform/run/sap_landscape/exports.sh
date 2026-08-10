#!/bin/bash
export                 ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"

unset SDAF_APPLICATION_CONFIGURATION_NAME

export SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME="tfstatesa"
unset SDAF_WORKLOAD_ZONE_KEYVAULT_NAME
# This is the name of the key vault to be used for this workload zone. 
export                  SDAF_WORKLOAD_ZONE_KEYVAULT_NAME="kv-deployer"
export             SDAF_CONTROL_PLANE_NAME="DEV-WEEU-DEP00"
export             SDAF_WORKLOAD_ZONE_NAME="DEV-WEEU-SAP01"
