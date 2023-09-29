# This is the SAP library’s storage account for sap binaries
if [ ! -n "${SAP_LIBRARY_TF}" ] ;then
  read -p "Please provide the saplib storage account name (SAP_LIBRARY)? "  saplib
else
  saplib="${SAP_LIBRARY_TF}"
fi

if [ ! -n "${AZURE_STORAGE_KEY}" ] ;then
  read -p "Please provide the saplib storage account account key (SAP_LIBRARY)? "  key
else
  key="${AZURE_STORAGE_KEY}"
fi


# This is the deployer keyvault
if [ ! -n "${SAP_KV_TF}" ] ;then
  read -p "Please provide the Deployer keyvault name? "  kv_name
else
  kv_name="${SAP_KV_TF}"
fi


end=`date -u -d "90 days" '+%Y-%m-%dT%H:%MZ'`

sas=?$(az storage container generate-sas --permissions rl --account-name $saplib --name sapbits --https-only  --expiry $end -o tsv --account-key "${key}")

az keyvault secret set --vault-name $kv_name --name "sapbits-sas-token" --value  "${sas}"
