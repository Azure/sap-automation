---
name: sdaf-failure-triage
description: >
  Triage a failed or suspicious SDAF run: distinguish a real failure from a
  green no-op or a clean plan reported as failure, map the observed symptom
  to a documented cause in `docs/local/troubleshooting.md`, and hand off to
  the stage-owning skill for retry. Use when a user says "SDAF run failed",
  "my deploy exited non-zero", "the plan was clean but exit 1", "the run said
  success but nothing was deployed", "state lock error", "unexpected
  replacement", "control plane stopped partway", "generated hosts.yaml
  missing", "workload-zone private endpoint failure", "workload-zone subnet policy failure",
  or "SDAF exit 2". Do NOT use to actually deploy or to redesign the workspace
  layout.
allowed-tools: shell
license: MIT
---

# SDAF Failure Triage

Action-loop skill. The entry point for "it broke". Maps observed symptoms to
the documented cause in `docs/local/troubleshooting.md` (and the stage docs'
own `§ Validate` / `§ Configuration preparation` sections) and hands off to
the stage-owning skill. This skill is a **router**, not the owner of any
per-stage fix.

## When to invoke

Trigger on: "SDAF run failed", "the plan was clean but the run exited 1",
"success but nothing deployed", "state lock", "unexpected replacement",
"control plane stopped partway", "generated hosts.yaml missing", "BOM files
not found", "removal is incomplete", "Ansible playbook failed",
"workload-zone private endpoint failure", "workload-zone subnet policy failure", "SDAF
exit 2".

Do NOT trigger on: pre-flight readiness (`sdaf-readiness-check`), authoring
tfvars (`sdaf-workspace-and-tfvars`), fresh deploy of a stage.

## Preconditions

- Collect the exit code and the last 200 lines of the run log before
  invoking. If you have neither, ask for them; do not guess.

## Recipe

### Step 1 — Establish exit-code intent

- `0` — Terraform / script signalled success. Still worth verifying the
  expected artefacts exist (some symptoms below are "success but nothing
  deployed").
- non-zero — real failure OR a validation-gate refusal (`exit 2` from
  `validate.sh` or a stage script). Treat `exit 2` as a validation gate
  that was intentionally tripped, not a bug; do not silence it.

### Step 2 — Map the symptom

Walk [`references/symptom-map.md`](references/symptom-map.md), which lists
every named failure class from `docs/local/troubleshooting.md` (plus the workload-zone private-endpoint / subnet-policy case owned by `sdaf-workload-zone` and anchored in `docs/local/04-00-workload-zone.md § Configuration preparation`) with its
canonical anchor and the owning skill. Pick the first row whose symptom
matches the observed signature.

If nothing matches, walk the "canonical 'clean plan reported as failure'
note" in `references/symptom-map.md`, which walks the stage `§ Validate`
sections. If nothing there matches either, say docs are silent on this
symptom and stop — do not invent a cause.

### Step 3 — Route to the stage-owning skill

Route to the stage-owning skill for the actual retry:

| Stage / symptom | Owning skill |
|---|---|
| Control plane | `sdaf-control-plane-bootstrap` |
| Workload zone (**including** the private-endpoint / subnet-policy workaround) | `sdaf-workload-zone` |
| SAP system | `sdaf-sap-system` |
| WORKSPACES/tfvars authoring issue | `sdaf-workspace-and-tfvars` |
| BOM file location / selection | `sdaf-bom-selection` |

### Step 4 — Confirm before retry

The retry safety rules — no `--force` / no `--auto-approve` / no state
edits / no concurrent execution / do not delete `.progress` markers — are
enforced by the shipped repo instructions (`.github/copilot-instructions.md`)
and by each stage skill's own recipe. This triage skill defers to the
stage-owning skill's retry section rather than restating those rules.

## Special cases (documented)

### Interrupted control-plane removal reports success

`docs/local/troubleshooting.md § Removal is incomplete` and
`docs/local/07-00-operations.md § Remove resources`: an interrupted
control-plane removal can exit "successfully" after `step=1` without
deleting the deployer. Diagnostic path: inspect
`.sap_deployment_automation`, persisted `step`, library destroy result, and
remaining deployer state / resources. Do not edit `step` to bypass the
guard. Removal itself is not implemented as an action-loop skill in this
wave; the triage skill exists to identify this pattern and point at the
documented diagnostic path.

### `success` but nothing was deployed

Cross-check the expected artefacts for the stage:

- Control plane: state in library storage account, metadata under
  `.sap_deployment_automation`, summary written
  (`docs/local/03-00-control-plane.md § Validate`, `§ Outcome`).
- Workload zone: `.tfvars` and backend metadata in the state account's
  `tfvars` container, zone Key Vault deployed
  (`docs/local/04-00-workload-zone.md § Validate`, `§ Outcome`).
- SAP system: infra deployed and `<SID>_hosts.yaml` /
  `sap-parameters.yaml` present
  (`docs/local/05-00-sap-system.md § Validate`, `§ Outcome`).

If artefacts are missing, treat the "success" as false and route to the
stage-owning skill.

## Hard rules

- Documented behaviour only (D19). If the symptom does not match a
  `docs/local/troubleshooting.md` section, a documented `§ Configuration
  preparation` / `§ Validate` cross-check, or the canonical Government
  disclaimer in `references/symptom-map.md`, say docs are silent and stop.
- Do not silently pass a non-zero exit code.
- Do not narrate benign log noise as a failure without a documented anchor.

## What this skill does NOT do

- Does not deploy or retry directly.
- Does not repair Terraform state (state repair is out of this wave).
- Does not restate stage-specific safety rules — the stage skills and
  `.github/copilot-instructions.md` own those.
- Does not reason about undocumented failure modes (e.g. Azure Government
  end-to-end, air-gapped, `ARM_ENVIRONMENT`). The canonical Government
  disclaimer lives in `references/symptom-map.md`.

## See also

- `sdaf-control-plane-bootstrap`, `sdaf-workload-zone`, `sdaf-sap-system`,
  `sdaf-workspace-and-tfvars`, `sdaf-bom-selection`.
- `docs/local/troubleshooting.md`, `docs/local/07-00-operations.md`,
  `docs/local/04-00-workload-zone.md § Configuration preparation`.