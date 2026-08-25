---
name: sdaf-workspace-and-tfvars
description: >
  Explain and validate the SDAF `WORKSPACES` layout (DEPLOYER / LIBRARY /
  LANDSCAPE / SYSTEM), the region-code naming convention, and how the four
  tfvars files hang off it. Grounded in `docs/local/README.md § Configuration
  and state layout`, `docs/region-codes.md`, and the samples repo
  `sap-automation-samples/docs/01-00-terraform-samples.md`. Use when a user
  says "how do I lay out WORKSPACES", "which tfvars go where", "SDAF naming
  convention", "how should I name my parameter files", "region code",
  "control-plane vs library vs landscape vs system
  tfvars", or "location_short". Do NOT use to deploy anything or to select a
  BOM (see sdaf-bom-selection).
allowed-tools: shell
license: MIT
---

# SDAF Workspaces and tfvars

Context-primer. Answers *"where does each tfvars go, and what must the
directory names look like?"* — grounded in the shipped docs. Hands off to the
matching deploy skill.

## When to invoke

Trigger on: "WORKSPACES layout", "which tfvars", "region code", "SDAF naming
convention", "location_short", "unkn fallback", "DEPLOYER/LIBRARY/LANDSCAPE/
SYSTEM".

Do NOT trigger on: deploying, running validate.sh (that's
`sdaf-readiness-check`), selecting a BOM (`sdaf-bom-selection`).

## The four workspaces

Docs (`docs/local/README.md § Configuration and state layout`) show a
`WORKSPACES/` tree **outside** the SDAF checkout with four leaves. Each leaf
holds a same-named `.tfvars` file:

```
WORKSPACES/
├── DEPLOYER/<ENV>-<CODE>-<DEPLOYER>-INFRASTRUCTURE/<same>.tfvars
├── LIBRARY/<ENV>-<CODE>-SAP_LIBRARY/<same>.tfvars
├── LANDSCAPE/<ENV>-<CODE>-<VNET>-INFRASTRUCTURE/<same>.tfvars
└── SYSTEM/<ENV>-<CODE>-<VNET>-<SID>/<same>.tfvars
```

Sources: `docs/local/README.md § Configuration and state layout`;
sample layout also documented in
`sap-automation-samples/docs/01-00-terraform-samples.md § Inputs`.

## Naming convention

`docs/region-codes.md § Where the region code appears` defines the tokens
and the pattern:

- `<ENV>` — DEV / QA / PRD / MGMT / LAB.
- `<CODE>` — the uppercase region code from `docs/region-codes.md § Supported
  regions`; unmapped regions fall back to `unkn` per
  `§ Unmapped regions fall back to unkn`.
- `<DEPLOYER>` — deployer identifier (e.g. `DEP00`, `DEP01`).
- `<VNET>` — network identifier (e.g. `SAP01`, `SAP02`).
- `<SID>` — SAP SID (e.g. `X00`, `HA2`, `WIN`).

Documented examples:
- `MGMT-WEEU-DEP01-INFRASTRUCTURE`
- `MGMT-WEEU-SAP_LIBRARY`
- `DEV-WEEU-SAP01-INFRASTRUCTURE`
- `DEV-WEEU-SAP01-X00`

See [`references/naming-and-region-codes.md`](references/naming-and-region-codes.md)
for the doc-cited example set plus the "region codes appear in six places"
note.

## Filename must match the containing directory

Every documented example uses the same name for the directory and the
`.tfvars` file inside it. Deploy scripts require you to `cd` into the
directory containing the tfvars and pass the basename only
(`docs/local/troubleshooting.md § A parameter file is not found`). Mismatch
between directory name / file name / declared environment/region/network/SID
is one of the shipped stage-script validation gates.

Do not "fix" a mismatch by editing state — re-name to match, or fix the
tfvars content.

## Relationship of the four workspaces

- **DEPLOYER + LIBRARY** together form the control plane; the library
  stores remote Terraform state.
- **LANDSCAPE** (workload zone) reads control-plane / deployer state.
- **SYSTEM** reads deployer + landscape state.

The enforced deploy order (control plane → workload zone → SAP system) is
stated in `sdaf-orientation-and-surface § The spine (order is enforced)`,
which is the canonical statement. Doc anchors: `docs/local/README.md
§ Complete the journey`; each stage doc's `§ What the automation does` /
`§ Outcome`.

## GitHub-Actions-generated SYSTEM tfvars

For the GitHub Actions surface, docs say `04-create-system-environment.yml`
generates and commits the SAP-system `WORKSPACES`
(`docs/documentation-source-map.md § Lifecycle capability sources`). Do not
hand-author the SYSTEM tfvars in that flow; treat the generation step as the
source of truth.

## Hand-off

- To validate a prepared workspace: `sdaf-readiness-check` (drives
  `validate.sh`).
- To deploy: `sdaf-control-plane-bootstrap` → `sdaf-workload-zone` →
  `sdaf-sap-system`.
- To pick a BOM referenced from SYSTEM tfvars: `sdaf-bom-selection`.

## See also

- `sdaf-readiness-check`, `sdaf-control-plane-bootstrap`,
  `sdaf-workload-zone`, `sdaf-sap-system`, `sdaf-bom-selection`.
- `docs/local/README.md`, `docs/region-codes.md`,
  `sap-automation-samples/docs/01-00-terraform-samples.md`.