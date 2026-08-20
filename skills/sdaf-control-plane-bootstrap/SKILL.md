---
name: sdaf-control-plane-bootstrap
description: >
  Deploy the SDAF control plane locally: prepare DEPLOYER and LIBRARY tfvars,
  review the plan, run `deploy_controlplane.sh` per
  `docs/local/03-00-control-plane.md § Run`, and validate the deployer +
  library + state hand-off. Grounded in `docs/local/03-00-control-plane.md`.
  Use when a user says "deploy the SDAF control plane", "run
  deploy_controlplane.sh", "bootstrap SDAF from an empty subscription",
  "install the deployer" or "create the SAP library". Do NOT use for workload
  zone (see sdaf-workload-zone), SAP system (see sdaf-sap-system), removal
  (`sdaf-safe-removal`), or Azure Government / sovereign-cloud deltas
  (`sdaf-sovereign-cloud`).
allowed-tools: shell
license: MIT
---

# SDAF Control Plane Bootstrap

Action-loop skill. Deploys the control plane strictly per
`docs/local/03-00-control-plane.md` for local execution. On ADO / GitHub
surfaces, defer stage mechanics to the surface bootstrap plugin — this skill
covers the shared control-plane semantics.

## When to invoke

Trigger on: "deploy the SDAF control plane", "run deploy_controlplane.sh",
"install the deployer", "create the SAP library", "bootstrap SDAF from empty".

Do NOT trigger on: workload zone, SAP system, software download, install,
removal, or state repair.

## Preconditions (documented gates)

- `sdaf-readiness-check` has passed
  (`docs/local/02-00-prepare-execution-environment.md § Readiness verification`;
  `docs/local/03-00-control-plane.md § Before you begin`).
- Control-plane config files (DEPLOYER + LIBRARY tfvars) are prepared under
  the documented `WORKSPACES` layout — see `sdaf-workspace-and-tfvars`
  (`§ Configuration preparation`, `§ Inputs`).
- The three required env vars are set
  (`docs/local/troubleshooting.md § A required export is missing`):
  `SAP_AUTOMATION_REPO_PATH`, `CONFIG_REPO_PATH`, `ARM_SUBSCRIPTION_ID`.

## Recipe

### Step 1 — Review the tfvars

Re-read the DEPLOYER and LIBRARY tfvars once
(`docs/local/03-00-control-plane.md § Review before execution`). Confirm
naming matches `docs/region-codes.md § Where the region code appears`.

### Step 2 — Confirm the review gate

Docs require an explicit review before every state-changing step
(`docs/local/03-00-control-plane.md § Review before execution`; `§ Run`).

### Step 3 — Run the documented control-plane deploy

From `CONFIG_REPO_PATH`, exactly per
`docs/local/03-00-control-plane.md § Run`:

```bash
set -e
cd "$CONFIG_REPO_PATH/WORKSPACES"
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh" \
    --deployer_parameter_file \
    "$CONFIG_REPO_PATH/WORKSPACES/DEPLOYER/<CONTROL_PLANE>-INFRASTRUCTURE/<CONTROL_PLANE>-INFRASTRUCTURE.tfvars" \
    --library_parameter_file \
    "$CONFIG_REPO_PATH/WORKSPACES/LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY/<ENVIRONMENT>-<LOCATION>-SAP_LIBRARY.tfvars" \
    --subscription "$ARM_SUBSCRIPTION_ID"
rc=$?
if [ $rc -ne 0 ]; then
  echo "control-plane exit=$rc — route to sdaf-failure-triage"
  exit $rc
fi
```

Do not claim success unless the exit code is `0` AND the validation checks
in Step 5 pass. Treat `exit 2` as a validation-gate failure that must not be
silenced.

### Step 4 — Do not update SDAF between plan and apply

`docs/local/01-00-prerequisites.md § Pin versions`.

### Step 5 — Validate

`docs/local/03-00-control-plane.md § Validate` and `§ Outcome`:

- Deployer + library deployed.
- Terraform state migrated to the library storage account (`tfstate`
  container) — see `§ What the automation does`.
- `.sap_deployment_automation` metadata populated (`§ What the automation
  does`, `§ Validate`).
- Summary written (`§ Outcome`).

## If the run fails

Route to **`sdaf-failure-triage`**. It walks
`docs/local/troubleshooting.md` and hands back the specific documented
anchor. Stage-owned preventive checks (that belong here rather than in
triage):

- Filename / directory / basename mismatch — fix before rerun
  (`docs/local/troubleshooting.md § A parameter file is not found`).
- Interrupted control-plane rerun with `--recover` — do so only after the
  state agrees
  (`docs/local/troubleshooting.md § A control-plane run stopped partway through`).

## Hard rules

- Documented behaviour only (D19). If a knob is not in the shipped docs or
  the script's own `--help`, do not describe it.
- Do not pass `--auto-approve` for reviewed local deployment
  (`docs/local/03-00-control-plane.md § Review before execution`).
- Do not `--force` casually
  (`docs/local/03-00-control-plane.md § Safe retry`).
- Repo-wide rules apply: **do not run `terraform fmt`** and follow the
  Terraform / Ansible / Python guidance in
  [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

## See also

- `sdaf-workspace-and-tfvars`, `sdaf-readiness-check`,
  `sdaf-workload-zone`, `sdaf-sap-system`, `sdaf-safe-removal`,
  `sdaf-sovereign-cloud`, `sdaf-failure-triage`.
- `docs/local/03-00-control-plane.md`, `docs/local/troubleshooting.md`,
  [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).