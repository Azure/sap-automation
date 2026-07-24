# Deploy an SAP system locally

## Outcome

The SAP-system infrastructure is deployed in the workload zone. The system
workspace contains generated Ansible inventory and SAP parameter files for
software download and installation.

## Before you begin

- Complete [workload-zone deployment](04-00-workload-zone.md).
- Confirm the workload-zone state key and remote-state account.
- Confirm VM-family quota, image availability, storage performance, DNS,
  load-balancer, availability-zone, and high-availability decisions.
- Confirm the configured operating systems and database topology are
  compatible with the intended SAP product.

## Inputs

Prepare:

`WORKSPACES/SYSTEM/<SAP_SYSTEM>/<SAP_SYSTEM>.tfvars`

Also identify:

- `<SAP_SYSTEM>`: Same-named system directory and `.tfvars` base name.
- `<CONTROL_PLANE>`: Control-plane name.
- `<WORKLOAD_ZONE>`: Workload-zone name.
- `<DEPLOYER_STATE_KEY>`: Deployer state blob name.
- `<LANDSCAPE_STATE_KEY>`: Usually
  `<WORKLOAD_ZONE>-INFRASTRUCTURE.terraform.tfstate`.
- `<STATE_STORAGE_ACCOUNT>`: Remote-state storage account name.
- `<STATE_SUBSCRIPTION_ID>`: Subscription containing that storage account.

## Configuration preparation

1. Copy a system example from the shared samples repository or download a
   reviewed SAP-system `.tfvars` file from the SDAF Web application.
2. Review the SAP SID, database SID, VM roles, VM sizes, disks, images,
   availability, load balancers, accelerated networking, credentials,
   existing-resource IDs, and optional services.
3. Review every resource replacement that could affect database or SAP
   application data.
4. Record approval of the complete system topology and cost.

## What the automation does

[`installer.sh`](../../deploy/scripts/installer.sh) with
`--type sap_system`:

- Loads control-plane and workload-zone metadata.
- Configures the `sap_system` Terraform root module.
- Reads deployer and landscape remote state.
- Runs Terraform plan with detailed exit codes.
- Checks plan output for replacement of state storage, SAP library storage,
  VMs, and managed disks.
- Applies the approved plan.
- Uploads configuration and metadata to the `tfvars` container.
- Generates `<SID>_hosts.yaml`, `sap-parameters.yaml`, inventory summaries,
  and other output files in the current system directory.
- Writes `apply_output.log` or `apply_output.json`.

[`installer_v2.sh`](../../deploy/scripts/installer_v2.sh) provides a v2
implementation. It uses `--parameter_file` instead of `--parameterfile` and
different state environment-variable names. Do not mix its options with the
established command.

## Review before execution

Review the complete Terraform plan.

> [!WARNING]
> Stop if the plan replaces a database VM, application VM, SCS VM, Web
> Dispatcher VM, managed data disk, SAP library storage account, or Terraform
> state storage account. Replacement can cause downtime or data loss.

Do not pass `--auto-approve`.

## Run

1. Change to the system parameter directory.

   ```bash
   cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
   ```

   The current directory contains `<SAP_SYSTEM>.tfvars`.

2. Run the SAP-system installer.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer.sh" \
     --type sap_system \
     --parameterfile "<SAP_SYSTEM>.tfvars" \
     --control_plane_name "<CONTROL_PLANE>" \
     --deployer_tfstate_key "<DEPLOYER_STATE_KEY>" \
     --landscape_tfstate_key "<LANDSCAPE_STATE_KEY>" \
     --storageaccountname "<STATE_STORAGE_ACCOUNT>" \
     --state_subscription "<STATE_SUBSCRIPTION_ID>"
   ```

   Terraform displays the plan and asks for approval before apply.

## Validate

1. Confirm that Terraform apply completed successfully.
2. Confirm that `apply_output.log` records the apply. Automation mode uses
   `apply_output.json` only as a transient processing artifact.
3. Confirm that the expected SAP-system resource group, VMs, disks, network
   interfaces, and load balancers exist.
4. Confirm that the system state blob is named
   `<SAP_SYSTEM>.terraform.tfstate`.
5. Confirm that `<SID>_hosts.yaml` exists in the system directory.
6. Confirm that `sap-parameters.yaml` exists in the system directory.
7. Confirm that the generated inventory contains the expected host groups and
   private addresses.
8. Confirm that the `tfvars/SYSTEM` path contains the uploaded configuration
   and generated files defined by the module.

## Safe retry

Rerun the same command with the same source, inputs, identity, and state after
correcting the failure. Review the new plan before approval.

If generated files are missing after a successful infrastructure apply,
inspect Terraform output and local-file errors before running Ansible. Do not
create an inventory manually unless it is reviewed against the module's
generated structure.

## Next step

[Download SAP software and run configuration and installation](06-00-software-and-installation.md).
