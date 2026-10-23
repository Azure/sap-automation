#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

keyvault_name=""
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
    name="${bom##*/}"
    name="${name%.original}"
    name="${name%.yaml}"
    echo "$name"
done | sort -u
