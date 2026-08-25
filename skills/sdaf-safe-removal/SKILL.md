---
name: sdaf-safe-removal
description: >
  Remove SDAF resources safely in reverse dependency order: stop SAP/database
  services, back up data and state evidence, remove SAP systems before the
  workload zone, remove workload zones before the control plane, and validate
  incomplete teardown before any retry or ARM fallback. Grounded in
  `docs/local/07-00-operations.md`, `docs/local/troubleshooting.md`,
  `deploy/scripts/remover.sh`, `deploy/scripts/remove_controlplane.sh`, and the
  Azure DevOps ARM-fallback pipeline. Use when a user asks to remove an SAP
  system, workload zone, or control plane, to run `remover.sh` or
  `remove_controlplane.sh`, or to explain why a control-plane removal exited 0
  while the deployer still exists. Do NOT use for explicit state `list` /
  `import` / `remove` operations (see `sdaf-state-management`) or generic
  failed-run triage (see `sdaf-failure-triage`).
allowed-tools: shell
license: MIT
---

# SDAF Safe Removal

Action-loop skill. Remove SDAF-managed resources only in the documented reverse dependency order and only after a reviewed destroy plan.

## When to invoke

Trigger on: "remove an SAP system", "remove the workload zone", "remove the control plane", "safe teardown", "run remover.sh", "run remove_controlplane.sh", "destroy left resources behind", "the control-plane removal said success but the deployer is still there".

Do NOT trigger on: explicit Terraform state surgery, generic failed-run triage, or greenfield deployment.

## Preconditions

- Approved removal scope, maintenance window, identity, and retention plan (`docs/local/07-00-operations.md § Inputs`, `§ Prepare an operational change`).
- SAP and database services stopped per product procedures, and business data, configuration, keys, logs, and state evidence backed up (`§ Remove resources`).
- Keep the approved SDAF commit, configuration revision, remote-state account, state keys, `.sap_deployment_automation` metadata, and destroy output (`§ Before you begin`, `§ Retain logs and evidence`).
- Run the stage script from the directory that contains the parameter file and pass the basename only (`docs/local/troubleshooting.md § A parameter file is not found`).

## Reverse-order guard

Apply this order on every teardown (`docs/local/07-00-operations.md § Remove resources`):

1. Remove each SAP system.
2. Remove workload-zone resources only after every dependent SAP system is removed.
3. Remove the control plane only after every dependent workload zone is removed.
4. Remove retained shared or external resources separately according to their ownership.

Do not continue to a broader scope until the narrower dependency is gone and the destroy output has been reviewed.

## Run one approved removal stage at a time

### Remove an SAP system

From `WORKSPACES/SYSTEM/<SAP_SYSTEM>`, exactly per `docs/local/07-00-operations.md § Remove an SAP system`:

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

Review the destroy plan and confirm only after backups and approvals are complete.

### Remove a workload zone

Only after every dependent SAP system is removed. From `WORKSPACES/LANDSCAPE/<WORKLOAD_ZONE>-INFRASTRUCTURE`, exactly per `docs/local/07-00-operations.md § Remove a workload zone`:

```bash
cd "$CONFIG_REPO_PATH/WORKSPACES/LANDSCAPE/<WORKLOAD_ZONE>-INFRASTRUCTURE"
ARM_SUBSCRIPTION_ID="<WORKLOAD_SUBSCRIPTION_ID>" \
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remover.sh" \
  --type sap_landscape \
  --parameterfile "<WORKLOAD_ZONE>-INFRASTRUCTURE.tfvars" \
  --control_plane_name "<CONTROL_PLANE>" \
  --deployer_tfstate_key "<DEPLOYER_STATE_KEY>" \
  --storageaccountname "<STATE_STORAGE_ACCOUNT>" \
  --state_subscription "<STATE_SUBSCRIPTION_ID>"
```

Confirm the workload-zone state and any retained shared resources match the approved removal scope before approval.

### Remove the control plane

Only after every dependent workload zone is removed. From `WORKSPACES`, exactly per `docs/local/07-00-operations.md § Remove the control plane`:

```bash
cd "$CONFIG_REPO_PATH/WORKSPACES"
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_controlplane.sh" \
  --deployer_parameter_file \
  "$CONFIG_REPO_PATH/WORKSPACES/DEPLOYER/<CONTROL_PLANE>-INFRASTRUCTURE/<CONTROL_PLANE>-INFRASTRUCTURE.tfvars" \
  --library_parameter_file \
  "$CONFIG_REPO_PATH/WORKSPACES/LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY.tfvars"
```

Review each destroy operation. Use `--keep_agent` only when the deployment agent retention was explicitly approved and you understand the resulting partial removal (`docs/local/07-00-operations.md § Remove the control plane`).

## If removal is incomplete

`docs/local/troubleshooting.md § Removal is incomplete` is canonical:

1. Preserve the destroy output.
2. Confirm the dependency order was respected.
3. Compare remaining Azure resources with the Terraform state list.
4. Resolve locks, permissions, policies, and delete protections.
5. For an SAP-system or workload-zone removal, rerun the same command and re-review the destroy plan.

### Control-plane partial-removal trap

Do **not** use the generic rerun rule for an interrupted control-plane removal. Inspect `$CONFIG_REPO_PATH/.sap_deployment_automation`, its persisted `step`, the library destroy result, and the remaining deployer state and resources (`docs/local/07-00-operations.md § Retry deterministically`, `docs/local/troubleshooting.md § Removal is incomplete`).

After the library destroy, `remove_controlplane.sh` persists `step=1`; a later invocation can exit successfully without destroying the deployer. Do not treat that exit as completion, do not edit the step to bypass the guard, and do not switch to ad-hoc resource-group deletion. Obtain expert review for a component-specific recovery path.

## ARM fallback — last resort, Azure DevOps only

The only documented ARM fallback here is the Azure DevOps removal fallback.
It removes SAP systems, the workload zone, and the region through ARM
resource-group deletion and is a fallback **only** when Terraform destroy does
not remove everything.

Use that pipeline only after:

- the normal reverse-order Terraform removal path was attempted,
- the destroy output was captured and reviewed,
- the approved scope still matches the remaining resource groups, and
- the operator explicitly approves a resource-group deletion fallback.

This repo does not document a local-script or GitHub Actions ARM-fallback procedure. Do not invent one.

## Hard rules

- Do not pass `--auto-approve` (`docs/local/07-00-operations.md § Review before execution`).
- Do not remove the remote-state account or edit state to hide a failure (`docs/local/troubleshooting.md § Removal is incomplete`).
- Do not run ad-hoc `az group delete`, direct ARM deletion, or explicit Terraform state `list` / `import` / `remove` commands in place of the documented sequence; the state-operation boundary belongs to `sdaf-state-management`.
- Do not treat a control-plane rerun that exits `0` after `step=1` as completed removal.
- Documented behaviour only; if the docs or shipped scripts are silent, stop.
- Repo-wide rules apply: follow [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

## See also

- `sdaf-state-management`, `sdaf-failure-triage`, `sdaf-control-plane-bootstrap`, `sdaf-workload-zone`, `sdaf-sap-system`.
- `docs/local/07-00-operations.md`, `docs/local/troubleshooting.md`, and
  `docs/local/README.md`.
