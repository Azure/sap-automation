---
name: sdaf-quality-assurance
description: >
  Validate a deployed SDAF SAP system through the SDAF-owned QA entry points:
  the local quality-assurance menu and the documented Azure DevOps pipeline
  13 path. Choose configuration checks vs functional
  tests, apply `TEST_GROUPS` / `TEST_CASES` safely, interpret
  `quality_assurance/` and `logs/`, and enforce the documented boundary that
  the GitHub Actions wrapper is still pending. Use when a user says "run
  quality assurance", "run configuration checks", "pipeline 13 QA", "offline
  HA validation", or "why does the report say No test results found". Do NOT
  use to deploy the SAP system or generate `sap-parameters.yaml` /
  `<SID>_hosts.yaml` (see `sdaf-sap-system`), or for a generic failed-run
  report with no QA-stage context (see `sdaf-failure-triage`).
allowed-tools: shell
license: MIT
---

# SDAF Quality Assurance

Action-loop skill. Validate an already deployed and installed SAP system
through SDAF's own QA surfaces only. Durable anchors and the full test matrix
live in [`references/qa-entrypoints.md`](references/qa-entrypoints.md).

## When to invoke
Trigger on: "run quality assurance", "run configuration checks", "run SAP
functional tests", "pipeline 13 QA", "offline HA validation", "read the QA
report", "why does the report say No test results found", or "which
TEST_GROUPS / TEST_CASES should I use".

Do NOT trigger on: deploying the SAP-system infrastructure, generating
`sap-parameters.yaml` or `<SID>_hosts.yaml`, software download, or a generic
"my SDAF run failed" report that is not yet tied to the QA stage.

## Surface availability
| Surface | Availability | What to do |
| --- | --- | --- |
| Local / scripted | Fully documented and runnable through the quality-assurance menu | Use this skill directly. |
| Azure DevOps | The operator documentation describes pipeline 13; the public bootstrap wrapper is still documented as proposed | Use this skill only if the operator already has a real pipeline-13 path. |
| GitHub Actions | Wrapper workflow is still documented as pending | Say the docs mark it pending and stop; do not invent the workflow. |

## Preconditions
- The SAP system is already installed and running; QA validates a configured
  system and does not install one.
- The system workspace contains `sap-parameters.yaml` and
  `<SAP_SID>_hosts.yaml`.
- Azure sign-in works and the operator can read the workload-zone Key Vault.
- The execution host can reach every inventory host over SSH.
- Local runs additionally require outbound `https://github.com`, `sudo`, and
  `ARM_CLIENT_ID` on multi-identity hosts.
- Azure DevOps runs additionally require a self-hosted agent.

## Safety and test modes
- `ConfigurationChecks` and offline HA validation are non-disruptive.
- Online `SAPFunctionalTests` are disruptive; require an approved maintenance
  window.
- Supported functional families are DB HA, SCS HA, and Azure Backup DB.
- Exact menu / pipeline / framework playbook mapping is in the reference
  file.

## Local path
1. Change to the system workspace:
   ```bash
   cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
   ```

2. Confirm required artifacts:

   ```bash
   test -f sap-parameters.yaml
   test -f "<SAP_SID>_hosts.yaml"
   ```

3. Start with configuration checks:

   ```bash
   trap 'rm -f -- "$PWD/sshkey"' EXIT
   "$SAP_AUTOMATION_REPO_PATH/deploy/ansible/quality_assurance_menu.sh"
   rm -f -- "$PWD/sshkey"; trap - EXIT
   test ! -e "$PWD/sshkey"
   ```

4. Narrow a functional run only by exporting the selection first:

   ```bash
   trap 'rm -f -- "$PWD/sshkey"' EXIT
   TEST_GROUPS="HA_SCS" \
   TEST_CASES="ascs-migration" \
   "$SAP_AUTOMATION_REPO_PATH/deploy/ansible/quality_assurance_menu.sh"
   rm -f -- "$PWD/sshkey"; trap - EXIT
   test ! -e "$PWD/sshkey"
   ```

## Selection rules
- `TEST_GROUPS` is one exact group name.
- `TEST_CASES` is a comma-separated list of framework `task_name` values, not
  display names; e.g. `ascs-migration`, not `Manual ASCS Migration`.
- Always set `TEST_GROUPS` when setting `TEST_CASES`.
- The preparation playbook writes the resolved selection to
  `artifacts/qa_test_selection.json`; use it to confirm the requested scope.
- Validate group and case names against the pinned framework version from
  `deploy/ansible/vars/ansible-input-api.yaml`.
- Offline HA runs additionally require `offline_validation/<inventory host>/cib`;
  otherwise stop before the playbook.

## Azure DevOps contract
When an SDAF ADO environment already exposes pipeline 13, this skill owns the
stage semantics:

- queue-time selection lives in `test_type`, `sap_functional_test_type`,
  `test_groups`, `test_cases`, and `offline_mode`;
- the prep script validates `extra_params` as `-e key=value` only;
- the run performs **Quality Assurance Setup**, then
  **Quality Assurance Execution** for the selected framework;
- logs and reports are collected from `SYSTEM/<config>/logs` and
  `SYSTEM/<config>/quality_assurance`.

If the operator cannot point to an actual wired pipeline-13 path, stop at the
documented availability boundary rather than assuming the proposed wrapper is
present.

## Validate

Confirm all of the following:

- `quality_assurance/` contains the HTML report.
- `logs/<test_group_invocation_id>.log` exists; it is the machine-readable
  JSONL result record.
- `logs/execution_<timestamp>.log` exists and matches the completion banner.
- `No test results found.` means no results log was produced, not that the run
  passed.
- For functional tests, the cluster returned to its expected state before the
  maintenance window closed.

## Routing boundaries

- Need to deploy the system first or generate `sap-parameters.yaml` /
  `<SID>_hosts.yaml` → `sdaf-sap-system`.
- Generic failed-run triage or a non-QA symptom → `sdaf-failure-triage`.
- Asked for a GitHub Actions QA wrapper → say the docs mark it pending and
  stop.
- Do not infer undocumented STAF-side behaviour or additional surfaces.

## See also

- [`references/qa-entrypoints.md`](references/qa-entrypoints.md)
- `sdaf-sap-system`, `sdaf-failure-triage`
- `docs/local/07-10-quality-assurance.md`, `docs/deployment-options.md`,
  `docs/documentation-source-map.md`, `docs/supportability.md`
