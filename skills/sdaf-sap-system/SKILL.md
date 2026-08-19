---
name: sdaf-sap-system
description: >
  Deploy SDAF SAP system infrastructure (VMs, disks, load balancers, HA
  inputs) after the workload zone exists. Drives `installer.sh --type
  sap_system` per `docs/local/05-00-sap-system.md § Run`, reviews replacement
  risk, and validates the generated `<SID>_hosts.yaml` /
  `sap-parameters.yaml`. Use when a user says "deploy an SAP system", "run
  installer.sh sap_system", "SAP system infrastructure", "generate the SAP
  system inventory". Do NOT use for OS/DB/SAP install (Ansible menus),
  workload zone (see sdaf-workload-zone), or software download.
allowed-tools: shell
license: MIT
---

# SDAF SAP System

Action-loop skill. Deploys the SAP-system infrastructure strictly per
`docs/local/05-00-sap-system.md`. Installation of OS + DB + SAP is a separate
concern and is not implemented in this wave.

## When to invoke

Trigger on: "deploy an SAP system", "run installer.sh sap_system", "SAP
system infra", "generated hosts.yaml", "generated sap-parameters.yaml".

Do NOT trigger on: control plane, workload zone, software download, install,
removal.

## Preconditions

- Workload zone deployed
  (`docs/local/05-00-sap-system.md § Before you begin`; SAP system reads
  deployer + landscape remote state per `§ What the automation does`).
- SYSTEM tfvars prepared under the documented WORKSPACES layout — see
  `sdaf-workspace-and-tfvars`.
- Host quota / image / topology reviewed
  (`docs/local/05-00-sap-system.md § Before you begin`, `§ Inputs`).

## Script family choice — do NOT mix v1 and v2

- **v1 (established):** `deploy/scripts/installer.sh` with `--type
  sap_system`. Invocation shape is documented in
  `docs/local/05-00-sap-system.md § Run`.
- **v2:** `deploy/scripts/installer_v2.sh`. Docs
  (`docs/local/05-00-sap-system.md § What the automation does`) note v2 has
  different options and state-variable names but do not provide a separate
  invocation-shape example under `§ Run`. Follow release guidance and the
  script's own `--help`; do not port v1 flags one-for-one.

**Do not mix v1 and v2 options.** If the operator has no
release-guidance-driven preference, say docs decline to pick and stop.

## Recipe

### Step 1 — Review replacement risk

Re-read the SYSTEM tfvars once, checking for anything that will cause a
resource replacement
(`docs/local/05-00-sap-system.md § Review before execution`; see also
`docs/local/troubleshooting.md § Terraform proposes unexpected replacement`).

### Step 2 — Run the installer (v1, documented shape)

From the system parameter directory, exactly per
`docs/local/05-00-sap-system.md § Run`:

```bash
set -e
cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
ARM_SUBSCRIPTION_ID="<WORKLOAD_SUBSCRIPTION_ID>" \
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer.sh" \
    --type sap_system \
    --parameterfile "<SAP_SYSTEM>.tfvars" \
    --control_plane_name "<CONTROL_PLANE>" \
    --deployer_tfstate_key "<DEPLOYER_STATE_KEY>" \
    --landscape_tfstate_key "<LANDSCAPE_STATE_KEY>" \
    --storageaccountname "<STATE_STORAGE_ACCOUNT>" \
    --state_subscription "<STATE_SUBSCRIPTION_ID>"
rc=$?
if [ $rc -ne 0 ]; then
  echo "SAP system exit=$rc — route to sdaf-failure-triage"
  exit $rc
fi
```

For v2, follow release guidance and `--help`; do not paste v1 flags into
`installer_v2.sh`.

### Step 3 — Validate

`docs/local/05-00-sap-system.md § Validate` and `§ Outcome`:

- SAP-system infra deployed.
- Generated `<SID>_hosts.yaml` and `sap-parameters.yaml` exist (`docs/local/05-00-sap-system.md § Validate`, `§ Outcome`).
- Config and metadata uploaded to the state account's `tfvars` container
  (`§ What the automation does`).

## If the run fails

Route to **`sdaf-failure-triage`**. Stage-owned preventive checks (kept
here rather than in triage):

- Filename / directory / basename mismatch — fix before rerun
  (`docs/local/troubleshooting.md § A parameter file is not found`).
- Do not delete `.progress` markers to force a rerun
  (`docs/local/06-00-software-and-installation.md § Safe retry`).

## Hard rules

- Documented behaviour only (D19).
- Do not deploy before the workload zone exists.
- Do not mix v1 and v2 options or state-variable names.
- Do not pass `--auto-approve`
  (`docs/local/05-00-sap-system.md § Review before execution`).
- Repo-wide rules apply: **do not run `terraform fmt`** and follow the
  Terraform / Ansible / Python guidance in
  [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

## What this skill does NOT do

- Does not run OS / DB / SAP installation playbooks.
- Does not download SAP media.
- Does not tear down or repair state.

## See also

- `sdaf-workload-zone`, `sdaf-workspace-and-tfvars`,
  `sdaf-bom-selection`, `sdaf-failure-triage`.
- `docs/local/05-00-sap-system.md`, `docs/local/troubleshooting.md`,
  [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).