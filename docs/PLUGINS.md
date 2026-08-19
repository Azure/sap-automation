# SDAF AI skills — install and use

This repository ships one AI-skills plugin, **`azure-sap-automation`**
(the **hub**), that works across supported agent CLIs (GitHub Copilot CLI,
Claude Code, Gemini CLI). It teaches your coding agent about SDAF using
only what this repository documents. Depending on how you run SDAF, you
may additionally install one **surface** plugin from a separate bootstrap
repository.

All SDAF AI plugins are **optional**; SDAF itself deploys with or without
them. Each plugin is independently installable and independently useful,
and nothing installs automatically — you run every command yourself.

## Contents

- [Which plugins do I install?](#which-plugins-do-i-install)
- [Install the hub plugin (`azure-sap-automation`)](#install-the-hub-plugin-azure-sap-automation)
- [Install a surface plugin (Azure DevOps or GitHub Actions)](#install-a-surface-plugin-azure-devops-or-github-actions)
- [Verify the installation](#verify-the-installation)
- [Use the skills — example prompts](#use-the-skills--example-prompts)
- [How the hub and surface plugins relate](#how-the-hub-and-surface-plugins-relate)
- [Current scope and what is not shipped yet](#current-scope-and-what-is-not-shipped-yet)
- [Ground rules and exclusions](#ground-rules-and-exclusions)
- [Troubleshooting](#troubleshooting)

## Which plugins do I install?

All plugins are optional. If you want AI coverage for how you actually run
SDAF, this is the complete map:

- **Local / scripted** — hub plugin (`azure-sap-automation`) only, from
  `Azure/sap-automation` (this repo).
- **Azure DevOps** — hub plugin **plus** the Azure DevOps surface plugin
  (`azure-sap-automation-devops`), from this repo **plus**
  `Azure/sap-automation-bootstrap`.
- **GitHub Actions** — hub plugin **plus** the GitHub Actions surface
  plugin (`azure-sap-automation-github`), from this repo **plus**
  `Azure/sap-automation-gh-bootstrap`.

Each plugin is independently installable, so you can add just the hub, just
a surface plugin, or both. Install the hub first if you want the guided
experience; the hub will name and print the install command for the
matching surface plugin when it's needed, and you run that command.

## Install the hub plugin (`azure-sap-automation`)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add Azure/sap-automation
copilot plugin install azure-sap-automation@sap-automation
```

### Claude Code

```text
/plugin marketplace add Azure/sap-automation
/plugin install azure-sap-automation@sap-automation
```

### Gemini CLI

Use the **extensions** form (not `gemini skills install`):

```bash
gemini extensions install https://github.com/Azure/sap-automation
```

The extension reads root `gemini-extension.json` and auto-loads root
`skills/`.

## Install a surface plugin (Azure DevOps or GitHub Actions)

Only install a surface plugin if you run SDAF from Azure DevOps or from
GitHub Actions. Local users skip this section entirely. The command shapes
below match the `docs/PLUGINS.md` in the bootstrap repositories.

### Azure DevOps — `azure-sap-automation-devops`

#### GitHub Copilot CLI

```bash
copilot plugin marketplace add Azure/sap-automation-bootstrap
copilot plugin install azure-sap-automation-devops@sap-automation-bootstrap
```

#### Claude Code

```text
/plugin marketplace add Azure/sap-automation-bootstrap
/plugin install azure-sap-automation-devops@sap-automation-bootstrap
```

#### Gemini CLI

```bash
gemini extensions install https://github.com/Azure/sap-automation-bootstrap
```

### GitHub Actions — `azure-sap-automation-github`

#### GitHub Copilot CLI

```bash
copilot plugin marketplace add Azure/sap-automation-gh-bootstrap
copilot plugin install azure-sap-automation-github@sap-automation-gh-bootstrap
```

#### Claude Code

```text
/plugin marketplace add Azure/sap-automation-gh-bootstrap
/plugin install azure-sap-automation-github@sap-automation-gh-bootstrap
```

#### Gemini CLI

```bash
gemini extensions install https://github.com/Azure/sap-automation-gh-bootstrap
```

## Verify the installation

A working hub install has two observable properties: the CLI's own plugin
manager lists the hub plugin, and it reports the eight skills the hub
ships.

### Step 1 — Mechanical check with the CLI's plugin manager

Run the listing command for your CLI. The hub plugin
`azure-sap-automation` (sourced from `Azure/sap-automation`) must appear.

#### GitHub Copilot CLI

```bash
copilot plugin list
```

#### Claude Code

In the Claude Code session, run the slash command:

```text
/plugin
```

#### Gemini CLI

```bash
gemini extensions list
```

### Step 2 — Confirm the eight hub skills

The hub ships exactly these eight skills; your CLI's plugin manager (or the
SKILL directory it exposes) should enumerate all of them:

1. [`sdaf-orientation-and-surface`](../skills/sdaf-orientation-and-surface/SKILL.md) — reach for it when you're new to SDAF or need to pick Local vs ADO vs GitHub.
2. [`sdaf-readiness-check`](../skills/sdaf-readiness-check/SKILL.md) — reach for it to pre-flight a host, subscription, and workspace before any deploy.
3. [`sdaf-workspace-and-tfvars`](../skills/sdaf-workspace-and-tfvars/SKILL.md) — reach for it to lay out `WORKSPACES` and tfvars per stage.
4. [`sdaf-bom-selection`](../skills/sdaf-bom-selection/SKILL.md) — reach for it to pick a BOM from the samples catalog.
5. [`sdaf-control-plane-bootstrap`](../skills/sdaf-control-plane-bootstrap/SKILL.md) — reach for it to deploy the deployer + SAP library from empty.
6. [`sdaf-workload-zone`](../skills/sdaf-workload-zone/SKILL.md) — reach for it to deploy a landscape after the control plane exists.
7. [`sdaf-sap-system`](../skills/sdaf-sap-system/SKILL.md) — reach for it to deploy SAP-system infrastructure and generate the Ansible inventory.
8. [`sdaf-failure-triage`](../skills/sdaf-failure-triage/SKILL.md) — reach for it to map a failed run to a documented cause.

The two **samples-origin primers** (`sdaf-workspace-and-tfvars`,
`sdaf-bom-selection`) teach `Azure/SAP-automation-samples` conventions that
every execution surface consumes, so they live in the hub — not in either
bootstrap repo — and load once regardless of which surface you pick.

### Step 3 — Prompt smoke test

Only after Steps 1 and 2 pass, open a new session and ask "what is SDAF and
where do I start?" — the agent should invoke `sdaf-orientation-and-surface`,
summarise the deployment spine, and ask which execution surface you want.
If the agent answers from general knowledge without naming a skill, the
plugin loaded incorrectly; see [Troubleshooting](#troubleshooting).

## Use the skills — example prompts

You invoke skills by describing your task in natural language; the trigger
phrases in each skill's `SKILL.md` map your request to the right skill. You
don't type skill names. Some prompts that work today:

- **Orient / choose a surface** — "I'm new to SDAF, where do I start?" ·
  "Local vs ADO vs GitHub Actions — which surface fits me?"
- **Pre-flight before any deploy** — "Am I ready to deploy the control plane?" ·
  "Run the SDAF readiness checks on this host." · "Validate my tfvars."
- **Lay out configuration** — "Show me the `WORKSPACES` layout and
  region-code naming for a new landscape." · "Where does the SAP-system
  tfvars file go?"
- **Pick a BOM** — "Which BOM should I use for S/4HANA 2023?" · "What's the
  difference between a product BOM and a component BOM?"
- **Deploy** — "Deploy the SDAF control plane from empty." · "Deploy a
  workload zone after the control plane exists." · "Deploy an SAP system
  and generate the Ansible inventory."
- **Triage** — "My control-plane deploy failed at library bootstrap — what
  do the docs say?" · "Ansible playbook 04 errored — walk me through the
  documented triage."

Each skill is scoped to what the shipped docs describe. When your question
goes past that, the skill will say so and stop rather than guess.

## How the hub and surface plugins relate

The hub, `azure-sap-automation`, ships in this repo (`Azure/sap-automation`)
and owns every skill that references code, docs, or samples living here —
including the samples-origin primers noted above. Those primers live in the
hub, not in either bootstrap repo, so they load once for every operator
regardless of surface.

A **surface plugin** — `azure-sap-automation-devops` or
`azure-sap-automation-github` — teaches the pipeline/workflow, service
connection, variable group, environment, and identity model of its own
platform, sourced from its own repository's docs. The hub never installs a
surface plugin for you; it prints the install command and points you at
this file. The operator runs the command.

## Current scope and what is not shipped yet

The hub currently ships the **eight** skills listed above under
[Verify the installation](#verify-the-installation). The catalogue will
grow over time, but the following are deliberately **not** included today:

- **Sovereign / Azure Government end-to-end procedures** — not shipped. The
  in-repo docs do not yet describe an end-to-end sovereign-cloud path;
  skills will surface the gap and stop rather than reconstruct a procedure
  the docs do not describe.
- **Azure Center for SAP solutions (ACSS) / Azure Monitor for SAP
  solutions (AMS)** — no dedicated skills today.
- **Additional operations, upgrade, and recovery skills** — planned for
  later; today, use the shipped docs and the general-purpose
  `sdaf-failure-triage` skill.

If your task falls in one of these areas, the skills will tell you and hand
off to the corresponding document rather than fabricate a procedure.

## Ground rules and exclusions

- **Documented behaviour only.** Skills teach what this repository (and, for
  BOM selection, `Azure/SAP-automation-samples`) documents. When a question
  falls outside the shipped docs — Azure Government end-to-end procedures,
  air-gapped / offline media, undocumented script flags, or an exhaustive
  tfvars catalogue — the skill surfaces the gap and stops rather than
  reconstructing behaviour from source.
- **Manual install only.** Skills never install other plugins automatically.
  They print the install commands in this file and the operator runs them.
- **No production-code changes.** These skills are documentation-driven
  primers and action-loops around already-shipped scripts. They do not edit
  Terraform modules, Ansible roles, or `deploy/scripts/`.
- **Out of scope for the hub.** ADO- or GitHub-specific pipeline, workflow,
  and identity procedures live in the surface plugin for that platform.

## Troubleshooting

- **Agent doesn't recognise SDAF skills after install.** Restart the agent
  session so it re-reads plugins, then re-run the listing command for your
  CLI (`copilot plugin list`, the `/plugin` slash command in Claude Code,
  or `gemini extensions list`) and confirm the hub plugin appears. If it
  does not, the install did not complete; consult the CLI's own install
  output and its `--help`.
- **`gemini skills install …` fails.** SDAF ships as a Gemini **extension**,
  not a stand-alone skill package — use
  `gemini extensions install https://github.com/Azure/sap-automation`.
- **Marketplace name doesn't match the plugin name.** That is expected: in
  Copilot CLI and Claude Code the form is
  `<plugin-name>@<marketplace-name>`, where the marketplace name matches
  the repository slug. For the hub it is
  `azure-sap-automation@sap-automation`.
- **Skill triggered for the wrong task.** Each `SKILL.md` lists both
  trigger phrases and explicit *"do NOT use for …"* exclusions. Re-phrase
  your request to match a listed trigger, or the skill you actually want.
- **A skill says the answer isn't in the docs.** That's by design — see
  [Current scope](#current-scope-and-what-is-not-shipped-yet). File
  an issue on this repository if the gap is worth closing later.

### Updating and uninstalling

Use your agent CLI's own plugin manager to update or uninstall SDAF plugins;
this repository does not publish version-specific syntax. Consult
`copilot plugin --help`, the Claude Code `/plugin` in-session menu, or
`gemini extensions --help` for the exact verbs your CLI version supports at
the time you run it. Do not treat "re-install" as an update path — install
the update through the CLI's documented update command instead.