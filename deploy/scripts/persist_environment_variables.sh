tf_bin=$(which terraform)
ansible_bin=$(which ansible)
# Ensure that the user's account is logged in to Azure with specified creds
az login --identity --output none
'echo ${USER} account ready for use with Azure SAP Automated Deployment'

#
# Create /etc/profile.d script to setup environment for future interactive sessions
#
echo '# Configure environment settings for deployer interactive sessions' | sudo tee /etc/profile.d/deploy_server.sh

echo export ARM_SUBSCRIPTION_ID=${subscription_id} | sudo tee -a /etc/profile.d/deploy_server.sh
echo export DEPLOYMENT_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/sap-automation | sudo tee -a /etc/profile.d/deploy_server.sh

echo export "PATH=${ansible_bin}:${tf_bin}:"'${PATH}':$HOME/Azure_SAP_Automated_Deployment/sap-automation/deploy/scripts:$HOME/Azure_SAP_Automated_Deployment/sap-automation/deploy/ansible | sudo tee -a /etc/profile.d/deploy_server.sh


# Set env for ansible
echo export ANSIBLE_HOST_KEY_CHECKING=False | sudo tee -a /etc/profile.d/deploy_server.sh
echo export ANSIBLE_COLLECTIONS_PATHS=${ansible_collections} | sudo tee -a /etc/profile.d/deploy_server.sh

# Set env for MSI
echo export ARM_USE_MSI=true | sudo tee -a /etc/profile.d/deploy_server.sh

az login --identity 2>error.log || :

if [ ! -f error.log ]; then
  az account show > az.json
  client_id=$(jq --raw-output .id az.json)
  tenant_id=$(jq --raw-output .tenantId az.json)
  rm az.json
else
  client_id=''
  tenant_id=''

fi

if [ ! -n "${client_id}" ]; then
  export ARM_CLIENT_ID=${client_id}
  echo export ARM_CLIENT_ID=${client_id} | sudo tee -a /etc/profile.d/deploy_server.sh
fi

if [ ! -n "${tenant_id}" ]; then
  export ARM_TENANT_ID=${tenant_id}
  echo export ARM_TENANT_ID=${tenant_id} | sudo tee -a /etc/profile.d/deploy_server.sh
fi

# Ensure that the user's account is logged in to Azure with specified creds
echo az login --identity --output none | sudo tee -a /etc/profile.d/deploy_server.sh
echo 'echo ${USER} account ready for use with Azure SAP Automated Deployment' | sudo tee -a /etc/profile.d/deploy_server.sh
