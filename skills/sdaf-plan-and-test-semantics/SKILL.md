---
name: sdaf-plan-and-test-semantics
description: >
  Explain SDAF plan-only / test / apply semantics without pretending they are
  universal. Compares the documented Local commands, Azure DevOps wrapper
  pipelines, and GitHub Actions workflows for control plane, workload zone,
  and SAP system: local stage commands show Terraform plans and then apply
  after approval; ADO/GitHub workload-zone and SAP-system test runs stop after
  the plan; the current hosted control-plane test options do not provide a
  plan-only run. Use when a user says "what does test do in SDAF", "is this a
  real dry run", "plan-only vs apply", "workflow 01 dry-run", "pipeline 02
  test", or "TEST_ONLY". Do NOT use to actually deploy a stage or to triage a
  failed run (see
  sdaf-control-plane-bootstrap / sdaf-workload-zone / sdaf-sap-system /
  sdaf-failure-triage).
allowed-tools: shell
license: MIT
---

# SDAF Plan and Test Semantics

Context-primer. Answers *"what does test / plan-only / apply mean here?"*
across surfaces. Canonical rule: **there is no SDAF-wide dry-run switch**.
Classify by execution surface and deployment stage before answering.

For the file-by-file evidence matrix, including the hosted wrapper docs and
workflow/pipeline paths, see
[`references/plan-test-matrix.md`](references/plan-test-matrix.md).

## When to invoke

Trigger on: "what does test do", "is this a dry run", "plan-only vs apply",
"control-plane dry-run limitation", "workflow 01 dry-run", "pipeline 02
test", "TEST_ONLY", "which SDAF stages can review a Terraform plan without
applying".

Do NOT trigger on: actually deploying a control plane / workload zone / SAP
system, or triaging a failed run after the fact.

## Rule zero — identify the surface and stage first

`docs/deployment-options.md` is explicit that Local, Azure DevOps, and GitHub
Actions are different execution models. Never answer *"test means X in
SDAF"* without naming:

- the surface (Local / ADO / GitHub); and
- the stage (control plane / workload zone / SAP system).

## The shortest correct answer

| Path | What plan/test means | What apply means |
|---|---|---|
| **Local control plane** | No separate documented `test` switch. `deploy_controlplane.sh` displays Terraform plans and asks for approval before apply. | The same run applies after operator approval. |
| **Local workload zone** | No separate documented local `test` path. `install_workloadzone.sh` shows the plan and waits for approval. | The same run applies after approval. |
| **Local SAP system** | No separate documented local `test` path. `installer.sh` shows the plan and waits for approval. | The same run applies after approval. |
| **ADO control plane (`01`)** | `test` exists on the wrapper/template, but current docs say it is **not forwarded** to the control-plane scripts. Treat it as **not plan-only**. | The queued run is state-changing. |
| **ADO workload zone (`02`)** | `test: true` becomes `TEST_ONLY` and the hosted installer exits after Terraform plan. | Re-queue the same pipeline with `test: false`. |
| **ADO SAP system (`03`)** | `test: true` becomes `TEST_ONLY` and the hosted installer exits after Terraform plan. | Re-queue the same pipeline with `test: false`. |
| **GitHub control plane (`01`)** | The workflow exposes a dry-run input, but the docs say it does **not** reach either control-plane script. | Treat the run as state-changing; get a reviewed control-plane plan through a separately validated SDAF path first. |
| **GitHub workload zone (`03`)** | Enable the test option, review the plan, then rerun with test disabled. The workflow exports `TEST_ONLY`. | Re-dispatch workflow `03` with test disabled. |
| **GitHub SAP system (`05`)** | Enable the test option, review the plan, then rerun with test disabled. The workflow exports `TEST_ONLY`. | Re-dispatch workflow `05` with test disabled. |

## Local / scripted semantics

For local execution, the docs do **not** define a universal `test` flag that
operators should export by hand. Instead, the documented stage commands
themselves are the review gate:

- `docs/local/03-00-control-plane.md § Run`: `deploy_controlplane.sh`
  displays Terraform plans and asks for approval before apply.
- `docs/local/04-00-workload-zone.md § Run`: `install_workloadzone.sh`
  displays the plan and asks for approval before apply.
- `docs/local/05-00-sap-system.md § Run`: `installer.sh` displays the plan
  and asks for approval before apply.

If the operator is on Local, answer with the documented stage command, not
with a hosted-only `TEST_ONLY` story.

## Hosted semantics

This is the boundary that prevents most bad advice:

For Azure DevOps or GitHub Actions, answer from the documented pipeline or
workflow inputs and outcomes. Do not transfer Local behavior to hosted
automation merely because both surfaces use the word `test`.

## Control-plane special case

The control plane is different from workload zone and SAP system:

- Local control-plane docs rely on interactive plan review inside the
  documented run.
- Current ADO and GitHub control-plane wrappers expose a `test`/dry-run
  input, but the reviewed docs say that input is not forwarded to the
  control-plane scripts.

So the correct answer to *"is control-plane `test` safe?"* is **no for the
hosted wrappers as currently documented**.

## Hard rules

- Do not claim there is a single SDAF-wide dry-run flag.
- Do not transfer Local behavior to hosted automation or vice versa.
- Do not tell an operator to rely on ADO/GitHub control-plane `test` as a
  safety gate.
- For local operator-reviewed deployment, do not add `--auto-approve`
  (`docs/local/03-00-control-plane.md § Review before execution`;
  `docs/local/04-00-workload-zone.md § Review before execution`;
  `docs/local/05-00-sap-system.md § Review before execution`).

## Hand-off

- Actual control-plane execution → `sdaf-control-plane-bootstrap`
- Actual workload-zone execution → `sdaf-workload-zone`
- Actual SAP-system execution → `sdaf-sap-system`
- Failed / contradictory run outcomes → `sdaf-failure-triage`

## See also

- [`references/plan-test-matrix.md`](references/plan-test-matrix.md)
- `sdaf-control-plane-bootstrap`, `sdaf-workload-zone`, `sdaf-sap-system`,
  `sdaf-failure-triage`
- `docs/deployment-options.md`, `docs/local/README.md`,
  `docs/local/03-00-control-plane.md`, `docs/local/04-00-workload-zone.md`,
  `docs/local/05-00-sap-system.md`
