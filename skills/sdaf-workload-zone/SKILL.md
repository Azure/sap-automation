---
name: sdaf-workload-zone
description: >
  Deploy an SDAF workload zone (landscape network, peering, zone Key Vault)
  after the control plane exists. Drives `install_workloadzone.sh` per
  `docs/local/04-00-workload-zone.md`, reviews the plan, and validates the
  state blob and summary. This skill owns the decision boundary for
  workload-zone private-endpoint / subnet-policy conflicts — inspect the
  actual Azure error and the workload-zone tfvars against
  `docs/local/04-00-workload-zone.md § Configuration preparation` before
  changing settings, and do not auto-apply a cloud-specific workaround
  outside its documented scope. Use when a user says "deploy a workload
  zone", "deploy the landscape", "run install_workloadzone.sh", "connect the
  workload zone to control-plane state", "workload-zone private endpoint
  failure", or "workload-zone subnet policy failure". Do NOT use for the
  control plane (see sdaf-control-plane-bootstrap) or SAP system (see
  sdaf-sap-system).
allowed-tools: shell
license: MIT
---

# SDAF Workload Zone

Action-loop skill. Deploys the workload zone per
`docs/local/04-00-workload-zone.md`. Canonical owner of workload-zone
private-endpoint / subnet-policy decisions — the failure-triage skill
routes those symptoms here.

## When to invoke

Trigger on: "deploy a workload zone", "deploy the landscape", "run
install_workloadzone.sh", "workload-zone Key Vault", "workload-zone private
endpoint failure", "workload-zone subnet policy failure".

Do NOT trigger on: control plane, SAP system, install, removal.

## Preconditions

- Control plane deployed (`docs/local/04-00-workload-zone.md § Before you
  begin`; the WZ reads control-plane / deployer state per
  `§ What the automation does`).
- Landscape tfvars prepared under the documented WORKSPACES layout — see
  `sdaf-workspace-and-tfvars` (`§ Configuration preparation`, `§ Inputs`).
- Remote-state / storage / connectivity / quota reviewed
  (`§ Before you begin`) — see `sdaf-readiness-check`.

## Recipe

### Step 1 — Review the plan

Re-read the landscape tfvars once and cross-check network, storage, Key
Vault, and peering
(`docs/local/04-00-workload-zone.md § Review before execution`).

### Step 2 — Run install_workloadzone.sh (documented shape)

From the landscape parameter directory, exactly per
`docs/local/04-00-workload-zone.md § Run`:

```bash
set -e
cd "$CONFIG_REPO_PATH/WORKSPACES/LANDSCAPE/<WORKLOAD_ZONE>-INFRASTRUCTURE"
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/install_workloadzone.sh" \
    --parameterfile "<WORKLOAD_ZONE>-INFRASTRUCTURE.tfvars" \
    --control_plane_name "<CONTROL_PLANE>" \
    --deployer_tfstate_key "<DEPLOYER_STATE_KEY>" \
    --storageaccountname "<STATE_STORAGE_ACCOUNT>" \
    --state_subscription "<STATE_SUBSCRIPTION_ID>" \
    --subscription "<WORKLOAD_SUBSCRIPTION_ID>" || {
  rc=$?
  echo "workload-zone exit=$rc — route to sdaf-failure-triage"
  exit "$rc"
}
```

Run from the directory that contains the tfvars; pass the basename only
(`docs/local/troubleshooting.md § A parameter file is not found`).

### Step 3 — Validate

`docs/local/04-00-workload-zone.md § Validate` and `§ Outcome`:

- Workload-zone `.tfvars` and backend metadata written to the state
  account's `tfvars` container (`§ What the automation does`).
- Zone Key Vault deployed (`§ Outcome`).
- Summary written.

## Decision: workload-zone private-endpoint and subnet-policy failures

**Canonical owner.** The failure-triage skill routes any workload-zone
private-endpoint or subnet-policy failure here rather than restating the
fix inline.

**Decision boundary — apply on every occurrence, do not shortcut:**

1. Read the exact Azure error text from the run log. Do not assume the
   error class from the operator's paraphrase.
2. Read the current values of the workload-zone private-endpoint and
   subnet-policy settings in the tfvars actually being applied.
3. Read `docs/local/04-00-workload-zone.md § Configuration preparation` for
   the current documented setting names, allowed values, and the specific
   cloud / condition under which the doc prescribes a change. Treat that
   section as the source of truth — it may evolve; this skill deliberately
   does not restate the setting name, allowed values, or the exact error
   string, so it cannot go stale against the doc.
4. Change only what the doc prescribes for the cloud you are deploying in.
   **Do not auto-apply a cloud-specific workaround (e.g. an Azure
   Government setting) to any other cloud** — the same doc section warns
   against that.
5. Re-review the plan (Step 1) before rerunning Step 2.

If the log's error text, the tfvars values, and the doc section do not
line up cleanly, say docs are silent on the specific combination and stop.
Do not synthesize a fix from analogous settings elsewhere.

## If the run fails

Route to **`sdaf-failure-triage`**, which walks the full symptom map. The
workload-zone-*owned* preventive checks that stay here rather than in
triage:

- Filename / directory / basename mismatch — fix before rerun
  (`docs/local/troubleshooting.md § A parameter file is not found`).
- Private-endpoint / subnet-policy failures — walk the decision boundary
  above.

## Hard rules

- Documented behaviour only (D19).
- Do not run before the control plane exists.
- Do not pass `--auto-approve`
  (`docs/local/04-00-workload-zone.md § Review before execution`).
- Do not `--force` casually
  (`docs/local/04-00-workload-zone.md § Safe retry`).
- Do not auto-apply a cloud-specific workaround outside the cloud the doc
  scopes it to (see the decision boundary above).
- Repo-wide rules apply: **do not run `terraform fmt`** and follow the
  Terraform / Ansible / Python guidance in
  [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

## See also

- `sdaf-control-plane-bootstrap`, `sdaf-workspace-and-tfvars`,
  `sdaf-sap-system`, `sdaf-state-management`, `sdaf-failure-triage`.
- `docs/local/04-00-workload-zone.md`, `docs/local/troubleshooting.md`,
  [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).