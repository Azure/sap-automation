# BOM selection: ordered decision walkthrough

Companion to `sdaf-bom-selection`. This file exists to hold the ordered
5-step selection procedure — the parent SKILL.md carries the topic-by-topic
facts, but does not sequence them into a single walkthrough. Read this file
when the operator asks *"walk me through picking a BOM"*.

1. Identify product family, release, DB platform, DB version, kernel, and
   topology (single-node / HA / scale-out).
   Doc: `sap-automation-samples/docs/02-00-bom-samples.md § Select and run
   a BOM`.
2. If the flow accepts a single BOM name, pick from `SAP/`. If the flow
   uses the four `sap-parameters.yaml` keys (`application_bom_name`,
   `database_bom_name`, `sap_kernel_bom_name`, `save_bom_as`), pick
   components from `BOM/`.
   Doc: `docs/local/06-00-software-and-installation.md § Inputs and BOM
   ownership`.
3. Open the candidate BOM YAML and check `supportedPlatforms`,
   `supportedDBVersions`, `supportedKernels`. The BOM YAML itself is the
   source of truth on currently allowed values — this walkthrough does not
   restate them.
   Doc: `sap-automation-samples/docs/02-00-bom-samples.md § Understand SAP
   and BOM`.
4. Prefer a pinned `v####` name over one containing `latest`.
   Doc: `sap-automation-samples/SAP/readme.md § BOM Name / BOM File`.
5. Pin the samples-repo checkout commit.
   Doc: `sap-automation-samples/docs/02-00-bom-samples.md § Select and run
   a BOM`.

For per-topic facts (where BOMs live, the `BOM_CATALOG` rule, product vs
component BOMs, the four keys, suffix decoding, hard rules), read the
parent SKILL.md. This file is deliberately kept narrow to the ordered
walkthrough so it does not drift from those facts.