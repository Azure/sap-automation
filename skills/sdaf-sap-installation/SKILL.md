---
name: sdaf-sap-installation
description: >
  Guide SDAF operating-system, database, and SAP installation after the SAP-system workspace and reviewed media are ready. Covers the local
  `configuration_menu.sh` path, the Azure DevOps `05-DB-and-SAP-installation` booleans, `.progress`-based recovery, and the boundary between
  infrastructure deployment, media acquisition, and software installation. Use for "run the SAP install playbooks", "which installation stage
  should I select", "resume after a partial DB/SAP playbook run", "run configuration_menu.sh", or "queue 05-DB-and-SAP-installation with the
  right booleans". Do NOT use for `sdaf-sap-system`, `sdaf-media-acquisition`, `sdaf-media-diagnostics`, or `sdaf-quality-assurance`.
allowed-tools: shell
license: MIT
---
# SDAF SAP Installation
Action-loop skill. Owns OS + DB + SAP installation **after** `sdaf-sap-system` has produced `sap-parameters.yaml` and `<SID>_hosts.yaml` and after the reviewed software set is available.

Preserve these boundaries:
- `sdaf-sap-system` owns infrastructure deployment and generated inventory.
- `sdaf-media-acquisition` / `sdaf-media-diagnostics` own `download_menu.sh`, BOM download, and library-media problems.
- `sdaf-sap-installation` owns the documented local installation menu and the
  Azure DevOps installation-stage selections.

Use [`references/install-stage-map.md`](references/install-stage-map.md) for
the operator-facing stage and recovery map.

## When to invoke
Trigger on: "run configuration_menu.sh", "install OS/DB/SAP", "05-DB-and-SAP-installation", "which playbook should I select", "resume after db-load", "SCS install", "PAS install", or ".progress markers".

Do NOT trigger on: SAP-system infrastructure deployment, library media download, GitHub workflow sequencing, STAF quality-assurance, HA diagnostics, or a generic failure report that has not yet been identified as an install-stage issue.

## Preconditions
- `sdaf-sap-system` has completed and the system directory contains `sap-parameters.yaml` and `<SID>_hosts.yaml` (`docs/local/05-00-sap-system.md § Validate`, `docs/local/06-00-software-and-installation.md § Before you begin`).
- SSH connectivity to every inventory host works, the workload-zone Key Vault contains the generated credentials, and the SAP library has capacity.
- SAP licenses, download credentials, backups, and the maintenance window are approved for the intended stage.
- If the operator still needs the four component BOM keys or `download_menu.sh`, stop and hand off to `sdaf-media-acquisition`.

## Recipe
### 1) Preserve ordering
Order is fixed: deploy SAP-system infrastructure → acquire media into the SAP library → run installation stages against the generated inventory. Do not collapse those into one "install everything" action.

Library media acquisition and host-side media preparation are separate
documented stages. Do not treat downloading media into the library as an
installation run.

### 2) Local execution
From the system directory, exactly per `docs/local/06-00-software-and-installation.md`:
```bash
cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
run_with_key_cleanup() (
  set -e
  trap 'rm -f -- "$PWD/sshkey"' EXIT
  "$@"
)
run_with_key_cleanup \
  "$SAP_AUTOMATION_REPO_PATH/deploy/ansible/configuration_menu.sh" \
  && test ! -e "$PWD/sshkey"
```
Then:
1. Select **Validate parameters** first.
2. Select one reviewed playbook or grouped sequence from [`references/install-stage-map.md`](references/install-stage-map.md).
3. Keep the cleanup wrapper around the menu. It removes the retrieved key
   without masking the menu's exit status.
Use the reference to select the smallest documented stage and verify its
completion evidence.

### 3) Azure DevOps execution
Use the documented Azure DevOps installation pipeline. Enable only the
reviewed installation stages; do not default to every stage.

If the question is really about GitHub workflow order or the blocked workflow 07 path, stop and say that workflow-order mechanics live in the separate GitHub Actions surface plugin `azure-sap-automation-github`. Use the documented install/use pattern in `docs/PLUGINS.md § Install a surface plugin (Azure DevOps or GitHub Actions)` or ask `sdaf-orientation-and-surface` to print that install block; do not invent ad-hoc workflow commands here.

### 4) Validate and recover
Success means the selected playbooks completed, the expected `.progress` markers exist, services are healthy, logs are retained, and the local `sshkey` has been removed.

If the run stops partway:
1. Record the **first failed numbered playbook**, target host, and exit code.
2. Check the owned `.progress` marker in the stage map.
3. Correct the failed prerequisite or task.
4. Rerun the **smallest applicable playbook or Azure DevOps boolean**, not the whole install spine by default.

Hand-offs:
- Missing `sap-parameters.yaml` / `<SID>_hosts.yaml` → `sdaf-sap-system`
- Missing library media, wrong BOM names, or downloader issues → `sdaf-media-acquisition` / `sdaf-media-diagnostics`
- Ambiguous or cross-stage failure classification → `sdaf-failure-triage`

## Hard rules
- Documented behaviour only (D19). If the docs or checked-in wrappers do not describe a flag, menu path, or recovery step, do not invent it.
- Do not start installation before the SAP-system-generated files exist.
- Do not skip **Validate parameters**.
- Do not use **All Playbooks** or "all booleans enabled" as the default rerun path on an existing system.
- Do not delete `.progress` markers merely to force a rerun.
- Do not leave `sshkey` in the workspace after local execution.
- Do not conflate library media acquisition with host-side BOM processing.
- Follow [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

## See also
- [`sdaf-sap-system`](../sdaf-sap-system/SKILL.md)
- `sdaf-media-acquisition`
- `sdaf-media-diagnostics`
- [`sdaf-failure-triage`](../sdaf-failure-triage/SKILL.md)
- `sdaf-quality-assurance`
- `sdaf-plan-and-test-semantics`
- `docs/local/06-00-software-and-installation.md`
- `docs/local/troubleshooting.md`
