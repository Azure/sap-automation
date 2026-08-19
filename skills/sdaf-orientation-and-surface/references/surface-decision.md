# Surface decision reference

Companion to `sdaf-orientation-and-surface`. Two questions, then hand off.

## Q1: Where does the config repo live?

- **Azure Repos / Azure DevOps** → Azure DevOps surface.
- **GitHub** → GitHub Actions surface.
- **Neither (workstation / deployer / automation host)** → Local.

Doc anchor: `docs/deployment-options.md § Select an execution model`.

## Q2: Do you need a capability only one surface provides?

Docs say the surfaces are "capability differences, not a ranking"
(`docs/deployment-options.md § Select an execution model`). The docs also
state ADO "does not currently provide verified one-to-one equivalents for all
GitHub generation workflows" (`§ Azure DevOps`), and Local has "no hosted
stage generator" (`§ Local or scripted execution`, `docs/local/README.md § Run
SDAF locally`).

Beyond that, this reference does not claim any surface is "best". If the user
needs a capability comparison beyond what the docs assert, say so and stop —
do not synthesize an inferred matrix (per D19: documented-only).

## Q3 (only if the user asks): Script family (v1 vs v2)?

Docs treat both v1 (established) and v2 as valid and decline to name one
"current" or "legacy" (`docs/local/README.md § Select a script family`). The
docs also warn: **do not mix v1 and v2 options or state variable names**
(`docs/local/03-00-control-plane.md § What the automation does`,
`docs/local/05-00-sap-system.md § What the automation does`). If the user has
no release-guidance-driven preference, tell them the docs decline to pick and
point them at `docs/local/README.md § Select a script family`. Do not pick for
them.

## Hand-off

| Surface chosen | Next skill | Install commands to print |
|---|---|---|
| Azure DevOps | `sdaf-readiness-check` | `docs/PLUGINS.md § Install: Azure DevOps surface plugin (`azure-sap-automation-devops`)` |
| GitHub Actions | `sdaf-readiness-check` | `docs/PLUGINS.md § Install: GitHub Actions surface plugin (`azure-sap-automation-github`)` |
| Local | `sdaf-readiness-check` | none (hub-only) |

The exact install commands are in [`docs/PLUGINS.md`](../../../docs/PLUGINS.md) and mirrored in the parent SKILL.md § *Print the surface bootstrap install command*.