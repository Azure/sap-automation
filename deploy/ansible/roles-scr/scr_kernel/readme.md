


Role
  tasks                   #  <-- tasks file can include smaller files if warranted
  handlers                #  <-- handlers files
  templates               #  <-- files for use with the template resource
  files                   # one or more files that are available for the role and it’s children.
  vars                    #  <-- variables associated with this role
  defaults                #  <-- default lower priority variables for this role
  meta                    #  <-- role dependencies
  library                 # roles can also include custom modules
  module_utils            # roles can also include custom module_utils
  lookup_plugins          # or other types of plugins, like lookup in this case





Functions
  inventory
  compare
  archive
  extract
  store
  retrieve
  cleanup


Targets
  Logging
  Storage




Calling Parameters
  Function  = inventory
    target  = source|destination
    sid     = SID
    type    = SAP|DB
  




MKDS1SECESAP00user210
deployer-kv-name                      configuration     Enabled       2/25/2027
MKDS1-SECE-SAP00-sid-password         secret            Enabled       2/25/2027
MKDS1-SECE-SAP00-sid-sshkey           secret            Enabled       2/25/2027
MKDS1-SECE-SAP00-sid-sshkey-pub       secret            Enabled       2/25/2027
MKDS1-SECE-SAP00-sid-username         configuration     Enabled       2/25/2027
MKDS1-SECE-SAP00-witness-accesskey    secret            Enabled       2/25/2027



az keyvault secret show
  --vault-name {{ kv_name }}
  --name {{ fencing_spn_client_id }}
  --query value
  --output tsv

az keyvault secret show                       \
  --vault-name  MKDS1SECESAP00user210         \
  --name        MKDS1-SECE-SAP00-sid-sshkey   \
  --query       value                         \
  --output      tsv


az keyvault secret show                       \
  --vault-name  MKDS1SECESAP00user210         \
  --name        MKDS1-SECE-SAP00-sid-username \
  --query       value                         \
  --output      tsv






ansible-playbook  --inventory   x_scr_testing_inventory_X90.yaml  \
                  --inventory   x_scr_testing_inventory_X91.yaml  \
                  --extra-vars  @x_scr_parameters.yaml            \
                  --private-key x_scr_testing.pem                 \
                  playbook_scr_mkd_testing.yaml                   \
                  -vvv


ansible-playbook  --inventory   x_scr_testing_inventory_X90.yaml  \
                  --inventory   x_scr_testing_inventory_X91.yaml  \
                  --extra-vars  @x_scr_parameters.yaml            \
                  playbook_scr_mkd_testing.yaml                   \
                  -vvv
