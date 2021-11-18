# This is the SAP library’s storage account for sap binaries
if [ ! -n "${SAP_LIBRARY_TF}" ] ;then
  read -p "Please provide the terraform state storage account from SAP_LIBRARY? "  saplib
else
  saplib="${SAP_LIBRARY_TF}"
fi



# This is the deployer keyvault
if [ ! -n "${SAP_KV_TF}" ] ;then
  read -p "Please provide the Deployer keyvault name? "  kv_name
else
  kv_name="${SAP_KV_TF}"
fi

end=`date -u -d "90 days" '+%Y-%m-%dT%H:%MZ'`

sas=?$(az storage account generate-sas --permissions rpl --account-name $saplib --services b --resource-types sco --expiry $end -o tsv)

az keyvault secret set --vault-name $kv_name --name "sapbits-sas-token" --value  "${sas}"
