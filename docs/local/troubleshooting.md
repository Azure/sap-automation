# Troubleshoot local execution

Use the first applicable section. Preserve the original error, command,
working directory, SDAF commit, tool versions, configuration revision, state
key, and Azure principal.

## A required export is missing

The infrastructure scripts validate:

- `SAP_AUTOMATION_REPO_PATH`
- `CONFIG_REPO_PATH`
- `ARM_SUBSCRIPTION_ID`

Run:

```bash
printf 'SAP_AUTOMATION_REPO_PATH=%s\n' "$SAP_AUTOMATION_REPO_PATH"
printf 'CONFIG_REPO_PATH=%s\n' "$CONFIG_REPO_PATH"
printf 'ARM_SUBSCRIPTION_ID=%s\n' "$ARM_SUBSCRIPTION_ID"
```

Each value must be nonempty and identify the intended source, configuration,
or subscription.

## A parameter file is not found

`install_deployer.sh`, `install_library.sh`, `install_workloadzone.sh`, and
`installer.sh` enforce working-directory rules. Run a stage-specific script
from the directory that contains its parameter file and pass the basename,
not a path with another directory component.

Run:

```bash
pwd
ls -l ./*.tfvars
```

Confirm the expected file is in the current directory.

## Terraform or Azure CLI is not found

Run:

```bash
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/helpers/check_workstation.sh"
```

If a tool is missing, load `/etc/profile.d/deploy_server.sh` when it was
created by `configure_deployer.sh`, or repair the approved tool installation.

## Azure authentication or authorization fails

Run:

```bash
az account show --output table
az account get-access-token --query expiresOn --output tsv
```

Confirm the intended principal, tenant, subscription, and unexpired token.
Check access to the target subscription, state storage, Key Vault, network,
DNS, and role-assignment scopes.

Do not grant broad permanent roles only to bypass an error. Identify the
specific operation and approved scope.

## The execution host cannot reach Key Vault or Storage

Check:

- DNS resolution for the public or private endpoint.
- Routes, peering, firewalls, proxies, and network security controls.
- Private DNS zone links.
- Storage and Key Vault network rules.
- Whether the script detected the correct execution-host public IP.

Retry only after connectivity is stable. A changing egress IP can invalidate
temporary network rules.

## Terraform reports a state lock

Confirm no other workflow, pipeline, operator, or process is using the same
state blob. Preserve the lock details. Remove a lock only after proving the
owning operation is no longer running and obtaining state-owner approval.

Do not run two execution models concurrently against the same state.

## Terraform proposes unexpected replacement

Stop before approval. Compare:

- The current `.tfvars` revision.
- The SDAF commit and provider lock data.
- Remote-state keys and control-plane or workload-zone names.
- Existing-resource IDs.
- Azure changes made outside Terraform.
- The previous successful plan or apply record.

SAP-system automation checks selected VM, disk, SAP library, and state storage
replacements. Workload-zone automation reports selected migration risks in the
console during local interactive execution. Its environment `.err` artifact is
written only when the script runs through Azure DevOps, so local operators must
retain the console output.

## A control-plane run stopped partway through

Inspect:

- Deployer and library state blobs.
- The environment metadata file under
  `$CONFIG_REPO_PATH/.sap_deployment_automation`.
- Its persisted `step` value.
- Deployer and library `apply_output.*`.
- Azure resource groups and the state storage account.

Rerun the identical command after correcting the cause. Use the established
script's `--recover` option only after the persisted step and component state
agree with the recovery path. Do not combine `--recover` and `--force` without
a reviewed state plan.

## Generated Ansible files are missing

Confirm the SAP-system Terraform apply completed in the system directory.
The output-files module writes `<SID>_hosts.yaml` and
`sap-parameters.yaml` to the current Terraform working directory and uploads
defined artifacts to the `tfvars` container.

Inspect `apply_output.*` and Terraform local-file errors. Rerun the same
SAP-system command and review the plan.

## BOM files are not found

Run:

```bash
printf 'BOM_CATALOG=%s\n' "$BOM_CATALOG"
test -d "$BOM_CATALOG/SAP"
test -d "$BOM_CATALOG/BOM"
```

`BOM_CATALOG` must identify the samples repository root. `download_menu.sh`
passes it as `BOM_directory`; the BOM utility searches its `SAP`, `BOM`, and
`archives` children.

Confirm the BOM names in `sap-parameters.yaml` match directories and YAML
files in the reviewed samples revision.

## An Ansible playbook fails

Record the first failed task and target host. Check:

- Inventory address and remote user.
- Retrieved SSH key and Key Vault password.
- Host reachability and privilege escalation.
- Operating-system repositories and package access.
- SAP media availability and disk space.
- The playbook's `.progress` marker.
- Product logs on the target host.

Correct the cause and rerun the smallest applicable playbook. Do not delete
progress markers until you have reviewed the owning role.

## Removal is incomplete

Do not remove the remote-state account or edit state to hide the failure.

1. Preserve the destroy output.
2. Confirm that dependent SAP systems were removed before the workload zone.
3. Confirm that workload zones were removed before the control plane.
4. Compare remaining Azure resources with the Terraform state list.
5. Resolve locks, permissions, policies, and delete protections.
6. Rerun the same removal command and review the destroy plan.

Use `advanced_state_management.sh` only when an Azure resource and its
Terraform address require an explicitly reviewed `list`, `import`, or
`remove` operation.

## Collect information for support

Include:

- Execution model: local.
- SDAF commit and script family.
- Host operating system and tool versions.
- Stage and exact entry point.
- Sanitized command and working directory.
- Sanitized configuration path and state key.
- Azure subscription and region.
- Exit code and relevant output.
- Whether a retry, recovery, state operation, or manual Azure change occurred.

Return to [Run SDAF locally](README.md).
