# Naming and region codes (documented)

Companion to `sdaf-workspace-and-tfvars`.

## Pattern per stage

Sourced from `docs/region-codes.md § Where the region code appears`:

- Control plane deployer: `<ENV>-<CODE>-<DEPLOYER>-INFRASTRUCTURE`
- SAP library: `<ENV>-<CODE>-SAP_LIBRARY`
- Workload zone: `<ENV>-<CODE>-<VNET>-INFRASTRUCTURE`
- SAP system: `<ENV>-<CODE>-<VNET>-<SID>`

## Documented examples

From `docs/region-codes.md` and the samples repo
`sap-automation-samples/Terraform/WORKSPACES/{DEPLOYER,LIBRARY,LANDSCAPE,
SYSTEM}/readme.md`:

- Control plane: `MGMT-WEEU-DEP00-INFRASTRUCTURE`, `MGMT-WEEU-DEP01-INFRASTRUCTURE`
- Library: `MGMT-WEEU-SAP_LIBRARY`
- Landscape: `DEV-WEEU-SAP01-INFRASTRUCTURE`, `QA-WEEU-SAP02-INFRASTRUCTURE`,
  `PRD-WEEU-SAP03-INFRASTRUCTURE`
- System: `DEV-WEEU-SAP01-X00`, `DEV-WEEU-SAP01-HAN`, `DEV-WEEU-SAP01-HA2`,
  `DEV-WEEU-SAP01-ORA`, `DEV-WEEU-SAP01-DB2`, `DEV-WEEU-SAP01-WIN`,
  `QA-WEEU-SAP02-Q00/Q01/Q02`, `PRD-WEEU-SAP03-P00/P01/P02`,
  `LAB-SECE-SAP04-L00`

The full sample system matrix (SID → DB platform / HA / OS) is not shipped
as a single documented table; the readmes list them per directory.

## Unmapped regions

`docs/region-codes.md § Unmapped regions fall back to unkn`: if the region
is not in the supported set, the code is `unkn`. That means a workspace can
be authored against `unkn` but you should confirm the region is intended
before deploying.

## "Region code is duplicated in six files"

`docs/region-codes.md` states the mapping is implemented across multiple
files and a region is only fully supported when it is present in all of
them. When adding a region, keep the six locations in sync per
`docs/region-codes.md § Add a region`. This is a contributor concern; the
operator-facing symptom is a region that "works in one place but not
another".

## Government / sovereign region codes

`docs/region-codes.md § Supported regions` includes `usgovarizona`,
`usgovtexas`, `usgovvirginia`. For everything beyond the mapping itself
(end-to-end Government procedures, `ARM_ENVIRONMENT`, Government DNS zone
blocks) see the canonical statement in
the canonical statement owned by `sdaf-failure-triage` (invoke that skill
for the current disclaimer text).