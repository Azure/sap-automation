# Deploy the control plane locally

## Outcome

The SDAF deployer and SAP library are deployed. Terraform state is stored in
the library state storage account, and local metadata identifies the control
plane for later stages.

## Before you begin

- Complete [execution environment preparation](02-00-prepare-execution-environment.md).
- Confirm the deployment identity can create the configured resources and
  role assignments.
- Confirm the management network, DNS, and state-storage design.
- Back up the configuration repository.

## Inputs

Prepare and review:

- `WORKSPACES/DEPLOYER/<CONTROL_PLANE>-INFRASTRUCTURE/<CONTROL_PLANE>-INFRASTRUCTURE.tfvars`
- `WORKSPACES/LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY.tfvars`

Define `<CONTROL_PLANE>` as the first three hyphen-separated name segments
used by the deployer configuration.

Define `<ENVIRONMENT>` and `<LOCATION>` as the environment and location codes
used by the library directory and parameter file.

## Configuration preparation

1. Copy deployer and library examples from
   [`Azure/SAP-automation-samples/Terraform/WORKSPACES`](https://github.com/Azure/SAP-automation-samples/tree/main/Terraform/WORKSPACES).
2. Review subscription IDs, resource groups, region, management networking,
   DNS, Key Vault, storage, deployer VM, authentication, and optional Web
   application settings.
3. Confirm that deployer and library names describe the same environment and
   location.
4. Commit or otherwise record the approved customer configuration.

## What the automation does

[`deploy_controlplane.sh`](../../deploy/scripts/deploy_controlplane.sh):

1. Validates the required exports and key parameters.
2. Calls `install_deployer.sh` for the deployer.
3. Calls `install_library.sh` for the SAP library.
4. Uses bootstrap modules while remote state does not yet exist.
5. Creates the state storage account through the library deployment.
6. Migrates deployer and library state to the Azure Storage `tfstate`
   container.
7. Persists environment metadata under
   `$CONFIG_REPO_PATH/.sap_deployment_automation`.
8. Writes apply output and a Markdown control-plane summary.

It can also invoke `installer.sh` for component migration steps required by
the control-plane orchestration.

`deploy_control_plane_v2.sh` implements the same lifecycle through sourced v2
functions and has different option and environment-variable names. Use it only
when selected by release guidance.

## Review before execution

Review the Terraform plan shown by each component. Pay particular attention to
role assignments, network ranges, public endpoints, Key Vault access, storage
replication, resource replacement, and monthly cost.

Do not pass `--auto-approve` for an operator-reviewed local deployment.

## Run

1. Change to the configuration root.

   ```bash
   cd "$CONFIG_REPO_PATH/WORKSPACES"
   ```

   The current directory contains `DEPLOYER` and `LIBRARY`.

2. Run the control-plane orchestrator.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh" \
     --deployer_parameter_file \
     "DEPLOYER/<CONTROL_PLANE>-INFRASTRUCTURE/<CONTROL_PLANE>-INFRASTRUCTURE.tfvars" \
     --library_parameter_file \
     "LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY.tfvars" \
     --subscription "$ARM_SUBSCRIPTION_ID"
   ```

   Terraform displays plans and asks for approval before apply. A successful
   run completes both deployer and library stages.

Use `install_deployer.sh` and `install_library.sh` directly only when you need
component-level execution and have reviewed their required working-directory
and state handoff. `install_deployer.sh` must run from the deployer parameter
directory. `install_library.sh` must run from the library parameter directory
and requires the deployer state folder.

## Validate

1. Confirm that both Terraform applies completed successfully in the console.
2. Confirm that `apply_output.log` exists in each component working directory,
   unless automation output mode produced `apply_output.json`.
3. Confirm that `$CONFIG_REPO_PATH/.sap_deployment_automation` contains the
   environment metadata file.
4. Confirm that the library output identifies the remote-state storage
   account.
5. Confirm that deployer and library state blobs exist in the `tfstate`
   container.
6. Confirm that the expected deployer and library resource groups exist.
7. Confirm that the generated control-plane Markdown summary contains the
   expected names.

## Safe retry

Rerun the same command with the same commit, parameter files, identity, and
state. Terraform reconciles completed resources and plans remaining work.

If the established control-plane orchestration was interrupted after a
component completed, inspect the persisted `step` value and component state
before using `--recover`. The script implements `--recover` specifically for
its persisted control-plane step flow.

Do not use `--force` as a general retry option. It changes how local Terraform
metadata is considered and can trigger state migration or replacement paths.

## Next step

[Deploy a workload zone](04-00-workload-zone.md).
