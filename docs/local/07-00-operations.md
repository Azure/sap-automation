# Operate, recover, and remove a local deployment

## Outcome

You can apply reviewed changes, retain evidence, recover state deliberately,
retry deterministically, and remove resources in dependency order.

## Before you begin

Keep the approved SDAF commit, configuration, remote-state account, state
keys, `.sap_deployment_automation` metadata, generated inventory, and logs.
Document any manual Azure changes.

## Inputs

For an operation, identify:

- `<SAP_SYSTEM>`: Same-named SAP-system directory and `.tfvars` base name.
- `<WORKLOAD_ZONE>`: Workload-zone name.
- `<CONTROL_PLANE>`: Control-plane name.
- `<ENVIRONMENT>` and `<LOCATION>`: Library environment and location codes.
- `<DEPLOYER_STATE_KEY>`: Deployer state blob name.
- `<LANDSCAPE_STATE_KEY>`: Workload-zone state blob name.
- `<STATE_STORAGE_ACCOUNT>`: Remote-state storage account name.
- `<STATE_SUBSCRIPTION_ID>`: Subscription containing the state account.
- `<WORKLOAD_SUBSCRIPTION_ID>`: Subscription containing the workload-zone and
  SAP-system resources.
- The matching deployment and removal script family.
- The Azure identity and maintenance window.
- Required backups, retained resources, and approvers.

## Prepare an operational change

1. Reconcile the deployment configuration, remote state, and Azure resources.
2. Record drift or manual Azure changes.
3. Back up business data and state before a risky or destructive operation.
4. Review dependencies on shared control-plane and workload-zone resources.
5. Approve the exact command, expected plan, validation, and rollback path.

## What the automation does

The stage installers reinitialize the matching Terraform root module, read
remote state, create a plan, apply approved changes, and refresh stage
metadata. `remover.sh` runs Terraform destroy for a selected `sap_system` or
`sap_landscape`. `remove_controlplane.sh` removes library and deployer
resources. `advanced_state_management.sh` lists, imports, or removes Terraform
state entries. Before every operation, including `list`, it runs
`terraform init -migrate-state -upgrade` against the supplied backend.

## Review before execution

Review state ownership, replacement or deletion, service downtime, backups,
retained shared resources, role assignments, locks, and the reverse dependency
order. Do not use `--auto-approve` for an operator-reviewed change or removal.

## Apply an approved change

1. Update one stage's deployment configuration.
2. Review the source-control diff.
3. Confirm the same SDAF and tool versions used by the environment, or approve
   an upgrade plan.
4. Run the same stage command without `--auto-approve`.
5. Review the complete Terraform plan.
6. Approve only the intended changes.
7. Validate Azure resources and dependent services.
8. Retain the configuration revision and apply output.

Apply stages in dependency order: control plane, workload zone, SAP system,
then Ansible configuration.

## Manage state safely

Remote Terraform state is the authoritative infrastructure record after
control-plane bootstrap. Local `.terraform/terraform.tfstate` files contain
backend metadata and can be uploaded to the `tfvars` container by the scripts;
they are not a substitute for the remote state blob.

Use
[`advanced_state_management.sh`](../../deploy/scripts/advanced_state_management.sh)
only for a reviewed state operation. It supports `list`, `import`, and
`remove` for `sap_deployer`, `sap_library`, `sap_landscape`, and `sap_system`.

> [!WARNING]
> `state rm` stops Terraform from managing a resource without deleting the
> Azure resource. `import` changes the resource-to-state association. An
> incorrect address or Azure resource ID can cause later replacement or
> deletion. Back up state and obtain expert review before either operation.

Before invoking the script, back up the target remote-state blob and the local
`.terraform/terraform.tfstate` backend metadata. Confirm that the existing
local metadata and the supplied subscription, storage account, container, and
key identify the intended backend.

> [!WARNING]
> The `list` operation is not read-only during initialization. Reject any
> unexpected prompt to copy or migrate state, reconcile the existing and target
> backends, and rerun only after expert review.

After completing these checks, list state:

```bash
cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/advanced_state_management.sh" \
  --parameterfile "<SAP_SYSTEM>.tfvars" \
  --type sap_system \
  --operation list \
  --subscription "<STATE_SUBSCRIPTION_ID>" \
  --storage_account_name "<STATE_STORAGE_ACCOUNT>" \
  --terraform_keyfile "<SAP_SYSTEM>.terraform.tfstate" \
  --workload_zone_name "<WORKLOAD_ZONE>" \
  --control_plane_name "<CONTROL_PLANE>"
```

The script initializes the matching root module with migration and provider
upgrade options, then writes the listed resources to `resources.lst`.

## Retain logs and evidence

Retain:

- The SDAF commit and installed tool versions.
- The approved `.tfvars` revision.
- Terraform plan and apply console output.
- `apply_output.log`. Automation mode removes its transient
  `apply_output.json` after processing.
- Stage Markdown summaries.
- Generated inventory and `sap-parameters.yaml`.
- Ansible output and product logs.
- State account, container, and blob names.

`plan_output.log` is transient in several scripts and can be removed during
execution. Capture the console or redirect a reviewed command at the operator
shell when your audit policy requires a persistent plan record.

Do not retain secrets in general-purpose logs. Debug mode prints environment
variables and can expose credentials.

## Retry deterministically

1. Stop after the first failed state-changing command.
2. Record the exit code and complete output.
3. Confirm the current Azure resources and remote-state lock.
4. Keep the same SDAF commit, tool versions, identity, parameter file, state
   account, state key, and provider selections. Preserve the generated
   `.terraform.lock.hcl` for every root module involved in the stage and
   compare it during the retry.
5. Treat any provider lock change as an upgrade that requires review and a
   new plan. The stage installers run `terraform init -upgrade`, and some root
   provider requirements, including `hashicorp/random`, don't constrain a
   version. The same SDAF commit and Terraform version therefore don't
   guarantee the same provider resolution.
6. Correct only the identified cause.
7. Rerun the same stage command.
8. Review the new plan before approval.

Do not use the generic rerun step for an interrupted control-plane removal.
After the library destroy, `remove_controlplane.sh` persists `step=1`, and a
later invocation can exit successfully without removing the deployer. Follow
[Removal is incomplete](troubleshooting.md#removal-is-incomplete) for a
reviewed component-specific recovery.

Use [Troubleshoot local execution](troubleshooting.md) for stage-specific
diagnostics.

## Remove resources

Remove resources in reverse dependency order:

1. Stop SAP and database services according to product procedures.
2. Back up business data, configuration, keys, and required logs.
3. Remove each SAP system.
4. Remove workload-zone resources only after every dependent SAP system is
   removed.
5. Remove the control plane only after every dependent workload zone is
   removed.
6. Remove retained shared or external resources separately according to their
   ownership.

### Remove an SAP system

> [!WARNING]
> This command runs Terraform destroy for the selected SAP system. It can
> permanently delete VMs, disks, network interfaces, and other resources.

```bash
cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
ARM_SUBSCRIPTION_ID="<WORKLOAD_SUBSCRIPTION_ID>" \
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remover.sh" \
  --type sap_system \
  --parameterfile "<SAP_SYSTEM>.tfvars" \
  --control_plane_name "<CONTROL_PLANE>" \
  --deployer_tfstate_key "<DEPLOYER_STATE_KEY>" \
  --landscape_tfstate_key "<LANDSCAPE_STATE_KEY>" \
  --storageaccountname "<STATE_STORAGE_ACCOUNT>" \
  --state_subscription "<STATE_SUBSCRIPTION_ID>"
```

Review the destroy plan and confirm only after backups and approvals are
complete.

### Remove a workload zone

> [!WARNING]
> Do not continue while any SAP system depends on the workload-zone state or
> resources.

```bash
cd \
  "$CONFIG_REPO_PATH/WORKSPACES/LANDSCAPE/<WORKLOAD_ZONE>-INFRASTRUCTURE"
ARM_SUBSCRIPTION_ID="<WORKLOAD_SUBSCRIPTION_ID>" \
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remover.sh" \
  --type sap_landscape \
  --parameterfile "<WORKLOAD_ZONE>-INFRASTRUCTURE.tfvars" \
  --control_plane_name "<CONTROL_PLANE>" \
  --deployer_tfstate_key "<DEPLOYER_STATE_KEY>" \
  --storageaccountname "<STATE_STORAGE_ACCOUNT>" \
  --state_subscription "<STATE_SUBSCRIPTION_ID>"
```

Confirm that the workload-zone state and retained shared resources match the
approved removal scope.

### Remove the control plane

> [!WARNING]
> Control-plane removal can delete the deployer, SAP library, Key Vaults, and
> the storage account that holds Terraform state and software. Export required
> state, configuration, keys, and software before approval.

```bash
cd "$CONFIG_REPO_PATH/WORKSPACES"
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_controlplane.sh" \
  --deployer_parameter_file \
  "$CONFIG_REPO_PATH/WORKSPACES/DEPLOYER/<CONTROL_PLANE>-INFRASTRUCTURE/<CONTROL_PLANE>-INFRASTRUCTURE.tfvars" \
  --library_parameter_file \
  "$CONFIG_REPO_PATH/WORKSPACES/LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY.tfvars"
```

Review each destroy operation. Use `--keep_agent` only when you have approved
retention of the deployment agent resource and understand the resulting
partial removal.

## Validate removal

1. Confirm each Terraform destroy reports success.
2. Confirm no dependent resource remains unexpectedly.
3. Confirm retained resources have an owner and documented state.
4. Confirm state and metadata cleanup matches the approved retention policy.
5. Confirm subscriptions have no unexpected continuing cost.

## Next step

Return to [Run SDAF locally](README.md) for another environment or use
[Troubleshoot local execution](troubleshooting.md) for an incomplete removal.
