---
name: sdaf-bom-selection
description: >
  Pick the right SDAF BOM for a target SAP product / release / DB platform /
  version / kernel / topology. Explains where BOMs live in the samples repo
  (`SAP/` for whole products, `BOM/` for components), decodes the `ms`,
  `v####`, and `latest` suffix conventions, points at the compatibility
  guardrails (`supportedPlatforms`, `supportedDBVersions`, `supportedKernels`),
  and reminds the operator that the download flow needs four explicit BOM
  keys in `sap-parameters.yaml`. Use when a user says "which BOM do I use",
  "product BOM vs component BOM", "SAP samples BOM catalog", "BOM_CATALOG",
  "S4/2023 BOM", "HANA BOM", or "how do I pick a BOM for HANA/Oracle/DB2/ASE".
  Do NOT use to author a new BOM, to acquire media (later wave), or to
  troubleshoot a checksum / 404 (later wave).
allowed-tools: shell
license: MIT
---

# SDAF BOM Selection

Context-primer. Helps a user *choose* an existing BOM from the samples
catalog. Grounded in `docs/local/06-00-software-and-installation.md § Inputs
and BOM ownership` and the samples-repo BOM docs
(`sap-automation-samples/docs/02-00-bom-samples.md`).

For an ordered 5-step end-to-end walkthrough (identify target → product vs
component BOM → compatibility fields → prefer pinned name → pin samples
commit), see [`references/bom-selection.md`](references/bom-selection.md);
this body carries the topic-by-topic facts.

## When to invoke

Trigger on: "pick a BOM", "which BOM", "product BOM vs component BOM",
"BOM_CATALOG", "SAP samples", "S4 2023 BOM", "HANA BOM", "Oracle BOM", "DB2
BOM", "compatibility guardrails".

Do NOT trigger on: authoring a new BOM, running `download_menu.sh`, media
404 / checksum troubleshooting, or install-time BOM failures.

## Where BOMs live

Docs
(`sap-automation-samples/docs/02-00-bom-samples.md § Understand SAP and BOM`;
`docs/local/06-00-software-and-installation.md § Inputs and BOM ownership`):

- **`sap-automation-samples/SAP/<name>/<name>.yaml`** — **product BOM**
  (whole product); pick this when the flow accepts a single complete
  definition (e.g. `sap-automation/deploy/pipelines/04-sap-software-download.yaml`).
- **`sap-automation-samples/BOM/<name>/<name>.yaml`** — **component BOM**
  (app / db / kernel); pick these when the flow supports dynamic assembly
  driven by the four `sap-parameters.yaml` keys documented below. Anchor:
  `sap-automation-samples/docs/02-00-bom-samples.md § Understand SAP and BOM`.
- **`sap-automation-samples/SAP/archives/`** — legacy only; do not use
  without explicit release guidance.

Filename rule (docs; samples): the directory name and the YAML basename
must match exactly, case-sensitive. A rename that breaks the pair breaks
selection.

## BOM_CATALOG must point at the samples root

`docs/local/06-00-software-and-installation.md § Inputs and BOM ownership`:

- Set `BOM_CATALOG` to the root of a reviewed samples checkout that
  contains both `SAP/` and `BOM/`.
- **Do not** set `BOM_CATALOG` to an individual BOM directory.
- `download_menu.sh` passes this value to Ansible as `BOM_directory`.

## The four BOM keys (download flow)

`docs/local/06-00-software-and-installation.md § Inputs and BOM ownership`
is explicit: the SAP-system-generated `sap-parameters.yaml` contains
`bom_base_name`, but the wrapper **overrides it** and requires four keys:

```yaml
application_bom_name: <APPLICATION_BOM>
database_bom_name:    <DATABASE_BOM>
sap_kernel_bom_name:  <KERNEL_BOM>
save_bom_as:          <COMBINED_BOM_NAME>
```

Without all four, the wrapper substitutes an empty value and the download
fails. This is a documented constraint — surface it whenever the operator
picks component BOMs.

## Compatibility guardrails

BOM YAML fields to check before picking (documented in
`sap-automation-samples/docs/02-00-bom-samples.md § Select and run a BOM` /
`§ Review before execution`; the same fields are present in every shipped
BOM at `sap-automation-samples/{SAP,BOM}/<name>/<name>.yaml` — open the
current candidate rather than a versioned example):

- `supportedPlatforms`
- `supportedDBVersions`
- `supportedKernels`
- `product_ids` (role-to-SAP-product-ID map)
- `materials.dependencies` (prerequisite BOMs)

For the current allowed values on any of these keys, read the target BOM
YAML itself and the samples-repo doc anchor above — those own the strings.
Do not select a BOM whose guardrails do not match the target topology.

## Suffix decoding

`sap-automation-samples/SAP/readme.md § BOM Name / BOM File` and
`§ 02-00-bom-samples.md § Select and run a BOM`:

- `ms` suffix — Microsoft-supplied BOM.
- `v####` suffix — serial version number.
- `latest` in a name — moving target; the docs warn that names containing
  `latest` can change later. Prefer a pinned `v####` name, and pin the
  samples-repo checkout commit, so a BOM selected today matches the media
  downloaded tomorrow
  (`sap-automation-samples/docs/02-00-bom-samples.md § Select and run a
  BOM`).

## Hand-off

- To validate a BOM: `check_bom.sh` (runs `yamllint`, `ansible-lint`, and
  `check_bom.yml`). Referenced in `sap-automation-samples/docs/02-00-bom-samples.md
  § Validate`. BOM authoring is a separate skill and is out of this wave.
- To acquire media once a BOM is selected: media acquisition is a separate
  skill and is out of this wave.
- To route BOM failures during a run:
  `docs/local/troubleshooting.md § BOM files are not found` → confirm
  `BOM_CATALOG` root, names, and files.

## Hard rules

- Documented behaviour only (D19). If asked about air-gapped / offline
  media, an undocumented compatibility mapping, or the meaning of `XBOM`,
  say docs are silent and stop.
- Do not add credentials or downloaded media to the samples repo
  (`sap-automation-samples/docs/02-00-bom-samples.md § Before you begin`).
- Do not point `BOM_CATALOG` at a single BOM directory.

## See also

- `sdaf-sap-system` (its generated `sap-parameters.yaml` is where the four
  BOM keys are set).
- `sdaf-workspace-and-tfvars` (where the samples checkout is separate from
  the SDAF checkout).
- `sap-automation-samples/docs/02-00-bom-samples.md`,
  `docs/local/06-00-software-and-installation.md`.