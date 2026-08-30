---
name: sdaf-state-management
description: >
  Inspect and repair SDAF Terraform state safely before any reviewed
  import/remove. Grounded in `docs/local/07-00-operations.md § Manage state
  safely`, `docs/local/troubleshooting.md § Terraform reports a state lock`,
  and `deploy/scripts/advanced_state_management.sh`. Use when a user says
  "advanced_state_management.sh", "terraform state list", "state import",
  "state rm", "repair SDAF state", "remote state disagrees with Azure", or
  "who owns this state lock". Do NOT use for teardown, reverse-order destroy,
  ARM fallback, or an unclassified failed run.
allowed-tools: shell
license: MIT
---

# SDAF State Management

Action-loop skill. Canonical owner of the warning that
`advanced_state_management.sh` re-inits on every op. Uses only the reviewed
`list` / `import` / `remove` path documented in the repo and the checked-out
script's own `--help`; refuses to invent a generic unlock or teardown path.

## When to invoke

Trigger on: `advanced_state_management.sh`, "terraform state list", "state import",
"state rm", "repair remote state", "backend metadata", "resources.lst", "state lock
owner", "remote tfstate disagrees with Azure".

Do NOT trigger on: destroy / teardown / ARM fallback / reverse-order removal,
`remover.sh`, `remove_controlplane.sh`, hosted removal wrappers, or a failed run
whose symptom is still ambiguous.

## Preconditions

- The operator has an approved state operation (`docs/local/07-00-operations.md
  § Prepare an operational change`).
- `SAP_AUTOMATION_REPO_PATH`, `CONFIG_REPO_PATH`, and `ARM_SUBSCRIPTION_ID` are
  set, or the missing-export gate is fixed first.
- The target root is known: `sap_deployer`, `sap_library`, `sap_landscape`, or
  `sap_system`.
- The parameter file, state subscription, storage account, and key identify the
  intended backend.
- For `import` or `remove`, the exact Terraform address and Azure resource ID
  are known. If not, stop and inspect first.

## Recipe
### Step 1 — Confirm the boundary before touching state
- **This skill owns** reviewed state inspection and repair through
  `deploy/scripts/advanced_state_management.sh`.
- **`sdaf-safe-removal` owns** Terraform destroy, reverse-order teardown,
  and removal through the documented SDAF operations.
- **`sdaf-failure-triage` owns** an ambiguous failed run before the operator has
  established whether the problem is readiness, deploy, removal, or state.

If the user is trying to delete resources or finish an incomplete teardown,
route to `sdaf-safe-removal`. Do not hide removal problems with state edits.

### Step 2 — Reconcile backend identity and back up first
Walk the checklist in [`references/state-safety.md`](references/state-safety.md):

- Remote state is authoritative after control-plane bootstrap; local
  `.terraform/terraform.tfstate` is backend metadata, not the source of truth.
- Back up the target remote-state blob and local backend metadata before **any**
  reviewed state operation.
- Confirm the local metadata, the supplied subscription/storage account/key, and
  any `.sap_deployment_automation` metadata all point at the same backend. The
  script can infer backend values when arguments are omitted; inspect before
  trusting.
- Preserve lock details and prove no other workflow, pipeline, operator, or process
  still owns the blob.

### Step 3 — Inspect first with the documented `list` path
Before changing anything, confirm the checked-out script contract:

```bash
"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/advanced_state_management.sh" --help
```

Then start with the non-destructive *intent* from the documented `list`
example in `docs/local/07-00-operations.md § Manage state safely`:

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

The script initializes the matching root module, writes `resources.lst`, and
only then lists resources. Treat any unexpected copy/migrate prompt as a stop
condition; reconcile the backend first and rerun only after review.

### Step 4 — Treat `import` / `remove` as reviewed repairs, never discovery
- `state rm` stops Terraform from managing a resource; it does **not** delete
  the Azure resource.
- The script validates `--azure_resource_id` with `az resource show --ids`
  before import. If that lookup fails, stop.
- `import` and `remove` are only valid once `resources.lst`, the Terraform address,
  and the Azure resource ID all match the reviewed target.
- Do not shorten, pattern-match, or guess a Terraform address or Azure resource
  ID.
- Do not use `state rm` to bypass a replacement, to make an incomplete removal
  look clean, or as a substitute for a destroy plan. Those are boundary
  violations: route to `sdaf-failure-triage` or `sdaf-safe-removal`.

If the docs, script output, Azure resource lookup, and stored metadata do not
line up cleanly, say docs are insufficient for a safe reviewed edit and stop.

### Step 5 — Re-list, retain evidence, then hand off
After any reviewed import/remove:

- rerun `--operation list` to confirm the new association;
- retain the command, output, state account, container, and blob names; and
- hand back to the owning stage skill for a fresh plan, or to `sdaf-safe-removal`
  if the next reviewed step is an actual teardown.

## Hard rules
- Documented behaviour only (D19). If the docs and checked-out script are silent,
  stop.
- Never synthesize destructive state edits, generic unlock commands, or an
  undeclared hosted recovery wrapper.
- Do not treat `list` as read-only; initialization can still migrate or upgrade
  backend/provider state.
- Do not run two execution models concurrently against the same state.
- Do not treat local backend metadata as the authoritative state record.

## What this skill does NOT do
- Does not perform teardown, destroy, ARM fallback, or generic failed-run triage.
- Does not invent a `terraform force-unlock` procedure or approve import/remove
  without backups and exact identifiers.

## See also
- `sdaf-safe-removal`, `sdaf-failure-triage`, `sdaf-control-plane-bootstrap`,
  `sdaf-workload-zone`, `sdaf-sap-system`.
- `docs/local/07-00-operations.md`, `docs/local/troubleshooting.md`, and
  [`references/state-safety.md`](references/state-safety.md).
