# Deploy a workload zone locally

## Outcome

The workload-zone network, shared services, Key Vault, storage, and related
resources defined by the landscape configuration are deployed and connected
to the control-plane state.

## Before you begin

- Complete [control-plane deployment](03-00-control-plane.md).
- Confirm the remote-state storage account and deployer state key.
- Confirm workload subscription access, DNS ownership, network peering, and
  quota.
- Confirm the execution host can reach the control-plane Key Vault and state
  storage account.

## Inputs

Prepare:

`WORKSPACES/LANDSCAPE/<WORKLOAD_ZONE>-INFRASTRUCTURE/<WORKLOAD_ZONE>-INFRASTRUCTURE.tfvars`

Also identify:

- `<CONTROL_PLANE>`: Control-plane name.
- `<DEPLOYER_STATE_KEY>`: Usually
  `<CONTROL_PLANE>-INFRASTRUCTURE.terraform.tfstate`.
- `<STATE_STORAGE_ACCOUNT>`: Library output
  `remote_state_storage_account_name`.
- `<STATE_SUBSCRIPTION_ID>`: Subscription containing the state account.

## Configuration preparation

1. Copy a landscape example from the shared samples repository or download a
   reviewed workload-zone `.tfvars` file from the SDAF Web application.
2. Review the workload subscription, virtual network, subnets, DNS, peering,
   Key Vault, storage, NFS, witness, transport, and optional existing-resource
   identifiers.
3. Confirm that `<WORKLOAD_ZONE>` follows the environment, location, and
   logical network naming used by the `.tfvars` file.
4. Record approval of the final configuration.

## What the automation does

[`install_workloadzone.sh`](../../deploy/scripts/install_workloadzone.sh):

- Loads control-plane metadata from
  `$CONFIG_REPO_PATH/.sap_deployment_automation`.
- Configures the `sap_landscape` Terraform root module.
- Reads deployer remote state.
- Runs Terraform plan with detailed exit codes.
- Checks plan output for selected replacement and data-loss risks.
- Applies the approved plan.
- Persists workload-zone metadata.
- Uploads the `.tfvars` file and local backend metadata to the state storage
  account's `tfvars` container.
- Writes `apply_output.log` or `apply_output.json` and a workload-zone
  Markdown summary.

## Review before execution

Review the plan for address-space changes, subnet replacement, DNS-zone
changes, storage replacement, Key Vault changes, role assignments, and
cross-subscription resources.

> [!WARNING]
> Stop if the script reports that the environment uses older Terraform
> templates or that the plan risks data loss. Review the complete plan and
> migration path before continuing.

## Run

1. Change to the landscape parameter directory.

   ```bash
   cd \
     "$CONFIG_REPO_PATH/WORKSPACES/LANDSCAPE/<WORKLOAD_ZONE>-INFRASTRUCTURE"
   ```

   The current directory contains
   `<WORKLOAD_ZONE>-INFRASTRUCTURE.tfvars`.

2. Run the workload-zone installer.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/install_workloadzone.sh" \
     --parameterfile "<WORKLOAD_ZONE>-INFRASTRUCTURE.tfvars" \
     --control_plane_name "<CONTROL_PLANE>" \
     --deployer_tfstate_key "<DEPLOYER_STATE_KEY>" \
     --storageaccountname "<STATE_STORAGE_ACCOUNT>" \
     --state_subscription "<STATE_SUBSCRIPTION_ID>"
   ```

   Terraform displays the plan and asks for approval before apply.

## Validate

1. Confirm that Terraform apply completed successfully.
2. Confirm that `apply_output.log` records the apply. Automation mode uses
   `apply_output.json` only as a transient processing artifact.
3. Confirm that the workload-zone resource group and configured shared
   services exist.
4. Confirm that the workload-zone state blob is named
   `<WORKLOAD_ZONE>-INFRASTRUCTURE.terraform.tfstate`.
5. Confirm that the `tfvars/LANDSCAPE` path contains the uploaded
   configuration and backend metadata.
6. Confirm that the workload-zone Markdown summary contains the expected
   subscription, network, Key Vault, and storage details.
7. Confirm connectivity and name resolution from the execution host or
   deployer to the workload zone.

## Safe retry

Rerun the same command after correcting the cause. Use the same commit,
configuration, state account, state key, and identity. Review the new plan.

Do not use `--force` unless you have reviewed its local-state handling and
have a state migration or recovery plan.

## Next step

[Deploy an SAP system](05-00-sap-system.md).
