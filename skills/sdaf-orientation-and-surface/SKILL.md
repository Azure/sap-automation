---
name: sdaf-orientation-and-surface
description: >
  Orient a newcomer to the SAP Deployment Automation Framework (SDAF): explain
  the spine (control plane → workload zone → SAP system → software → install →
  operate/remove), summarise the three execution surfaces (Local, Azure DevOps,
  GitHub Actions), and print the install command for the matching surface
  bootstrap plugin — as documented in this repository's `docs/PLUGINS.md` —
  so the operator can run it manually. Use when a user says "what is SDAF",
  "where do I start with SDAF", "which surface should I use", "SDAF Local vs
  ADO vs GitHub", "how do I install the SDAF ADO/GitHub plugin", or "I'm new
  to SDAF". Do NOT use for readiness pre-flight (see sdaf-readiness-check),
  workspace/tfvars layout (see sdaf-workspace-and-tfvars), or troubleshooting
  a failed run (see sdaf-failure-triage).
allowed-tools: shell
license: MIT
---

# SDAF Orientation and Surface Choice

Primer skill. Answers *"what is SDAF and which execution surface should I use?"*
and hands off to the next action-loop skill. Grounded in the shipped docs; no
inferred procedures.

## When to invoke

Trigger on: "what is SDAF", "where do I start", "SDAF surface", "Local vs ADO
vs GitHub", "SDAF plugin install command", "how do I install azure-sap-automation-devops",
"which surface for SDAF".

Do NOT trigger on: pre-flight readiness checks, tfvars/WORKSPACES authoring,
BOM selection, failed-run triage. Route to the sibling skill instead.

## The spine (order is enforced)

Docs enforce this order for every surface:

1. **Control plane** — deployer + SAP library, establishes remote Terraform
   state (`docs/local/03-00-control-plane.md § Outcome`, `§ What the
   automation does`).
2. **Workload zone** — landscape / networking / zone Key Vault; reads
   control-plane state (`docs/local/04-00-workload-zone.md § Outcome`).
3. **SAP system** — VMs + inventory; reads deployer + landscape state
   (`docs/local/05-00-sap-system.md § Outcome`).
4. **Software download** — needs the workload-zone Key Vault credentials
   (`docs/local/06-00-software-and-installation.md § Download software`).
5. **Install** — OS + DB + SAP via Ansible playbooks
   (`docs/local/06-00-software-and-installation.md § Run configuration and installation`).
6. **Operate / recover / remove** — reverse dependency order for removal
   (`docs/local/07-00-operations.md § Remove resources`).

Never let a stage run before the prior one completed
(`docs/local/README.md § Complete the journey`).

## The three execution surfaces

Docs explicitly frame the surfaces as "capability differences, not a ranking":
there is **no declared primary** (`docs/deployment-options.md § Select an
execution model`). They are not one-to-one equivalent.

| Surface | When it fits | Doc anchor |
|---|---|---|
| **Local / scripted** | You run `deploy/scripts/*` directly from a workstation, deployer, or automation host. No hosted stage generator. | `docs/deployment-options.md § Local or scripted execution`; `docs/local/README.md § Run SDAF locally` |
| **Azure DevOps** | Azure Repos/Pipelines, service connections, agent pools own the process. Wrapper pipelines exist but docs note ADO "does not currently provide verified one-to-one equivalents for all GitHub generation workflows". | `docs/deployment-options.md § Azure DevOps` |
| **GitHub Actions** | GitHub owns the config repo and approvals. Includes stage-generation workflows and deploy workflows. | `docs/deployment-options.md § GitHub Actions` |

See [`references/surface-decision.md`](references/surface-decision.md) for the
two-question decision walkthrough and the hand-off to the next skill.

## What this skill does and does NOT do

**Does:** classify the request, explain the spine, help pick a surface, and
*print* the install command for the matching bootstrap plugin — the operator
runs it themselves.

**Does NOT:** install anything. Does not run a plan/apply. Does not fabricate
"which surface is best" — the docs decline to rank them and this skill honours
that.

## Print the surface bootstrap install command

The canonical install commands for the hub and both surface plugins are
documented in [`docs/PLUGINS.md`](../../docs/PLUGINS.md) (this repo). Print
the block that matches the operator's chosen surface **verbatim** from that
file, and instruct the operator to run it themselves. Do not invent
alternatives, do not paraphrase, do not shorten.

The exact command shapes at the time this skill was authored (source:
`docs/PLUGINS.md`):

**Azure DevOps** — from `docs/PLUGINS.md § Install: Azure DevOps surface plugin (`azure-sap-automation-devops`)`:

```text
# GitHub Copilot CLI
copilot plugin marketplace add Azure/sap-automation-bootstrap
copilot plugin install azure-sap-automation-devops@sap-automation-bootstrap

# Claude Code
/plugin marketplace add Azure/sap-automation-bootstrap
/plugin install azure-sap-automation-devops@sap-automation-bootstrap

# Gemini CLI
gemini extensions install https://github.com/Azure/sap-automation-bootstrap
```

**GitHub Actions** — from `docs/PLUGINS.md § Install: GitHub Actions surface plugin (`azure-sap-automation-github`)`:

```text
# GitHub Copilot CLI
copilot plugin marketplace add Azure/sap-automation-gh-bootstrap
copilot plugin install azure-sap-automation-github@sap-automation-gh-bootstrap

# Claude Code
/plugin marketplace add Azure/sap-automation-gh-bootstrap
/plugin install azure-sap-automation-github@sap-automation-gh-bootstrap

# Gemini CLI
gemini extensions install https://github.com/Azure/sap-automation-gh-bootstrap
```

**Local** — no surface plugin is required. Hand off directly to
`sdaf-readiness-check`.

The Copilot install form is `<plugin-name>@<marketplace-name>` where the
marketplace name matches the repository slug (e.g.
`sap-automation-bootstrap`), not the plugin name. If `docs/PLUGINS.md` and
this skill body ever diverge, `docs/PLUGINS.md` is the source of truth —
update this skill in lockstep.

## Hand-off

After the surface is chosen and the surface plugin (if any) is installed by
the operator, hand off to `sdaf-readiness-check` for pre-flight, then
`sdaf-workspace-and-tfvars` before any deploy skill.

## See also

- [`docs/PLUGINS.md`](../../docs/PLUGINS.md) — canonical install commands.
- `sdaf-readiness-check`, `sdaf-workspace-and-tfvars`,
  `sdaf-control-plane-bootstrap`.
- `docs/local/README.md`, `docs/deployment-options.md`.