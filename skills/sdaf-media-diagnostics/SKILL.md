---
name: sdaf-media-diagnostics
description: >
  Diagnose SDAF software-download and BOM-processing failures after a BOM is
  already selected. Covers the documented local media path, SAP download,
  storage-account upload/download, checksum validation, and
  `SAPCAR` / `.EXE` extraction. Use when a user says "download_menu failed",
  "BOM downloader 404", "missing archive", "checksum mismatch", "SAPCAR
  failed", "bom-processing-done missing", or "my SPS07 media run can't find
  a file". Do NOT use to choose a BOM (see `sdaf-bom-selection`), to run a
  clean first-time media download with no failure, or to diagnose a later
  non-media install failure.
allowed-tools: shell
license: MIT
---

# SDAF Media Diagnostics

Action-loop skill. Diagnoses failures on the local software path after the
operator already chose the BOM and started either `download_menu.sh` or BOM
processing from `configuration_menu.sh`. Grounded in
`docs/local/06-00-software-and-installation.md`,
`docs/local/troubleshooting.md`, and `docs/PLUGINS.md`. No invented recovery
paths.

## When to invoke

Trigger on: "download_menu failed", "BOM downloader 404", "missing archive",
"checksum mismatch", "SAPCAR failed", "bom-processing-done missing",
"SPS07 media file missing".

Do NOT trigger on: choosing a BOM/version, running a clean first download, or
a later DB/SAP install failure after media staging.

## Preconditions

- Collect the exact failing command or menu step, exit code, and last 200 lines
  of output.
- Identify whether the failure happened in:
  - the documented media acquisition step; or
  - BOM processing during configuration and installation.
- If the operator only says "SPS07" or similar product/version words, ask
  whether this is a BOM-choice question or a concrete failing file.

## Recipe

### Step 1 — Classify the failing lane

- **Acquisition lane** — use
  `docs/local/06-00-software-and-installation.md § Download software` and its
  documented inputs.
- **Processing lane** — use
  `§ Run configuration and installation` and its safe-retry guidance.
- If the failure is in a later numbered install playbook rather than BOM
  acquisition / processing, stop and route to `sdaf-sap-installation`
  or `sdaf-failure-triage` if the install-stage owner is still ambiguous.

### Step 2 — Walk the symptom map

Use [`references/media-symptom-map.md`](references/media-symptom-map.md) and
match the *exact* signature before suggesting any retry. The map covers:

- missing `sap-parameters.yaml` / `BOM_CATALOG`
- BOM not found
- `s_user` / `s_password` or storage-account auth failures
- archive `404` / missing blob
- checksum mismatch
- `SAPCAR` / `.EXE` extraction failures
- missing `.progress/bom-processing-done`
- offline / air-gapped asks that the repo does not document

If nothing matches, say the shipped docs/code do not describe this media
failure and stop.

### Step 3 — Re-read the current BOM and documented inputs

The authoritative inputs are the current `sap-parameters.yaml`, the selected
BOM YAML, and the operator documentation:

- `docs/local/06-00-software-and-installation.md § Inputs and BOM ownership` —
  `BOM_CATALOG` must point at the samples root; `download_menu.sh` requires
  `application_bom_name`, `database_bom_name`, `sap_kernel_bom_name`, and
  `save_bom_as`.
- `docs/local/06-00-software-and-installation.md § Configuration preparation`
  — review the current BOM's URLs, archive names, checksums, and target
  product versions.
Do not rename files, replace URLs, or invent checksums from memory.

### Step 4 — Retry only the minimal documented step

- For acquisition-lane failures, fix the matched precondition or BOM/input
  issue, then rerun **BOM Downloader** from `download_menu.sh`.
- For processing-lane failures, rerun the smallest applicable playbook from
  `configuration_menu.sh`;
  `docs/local/06-00-software-and-installation.md § Safe retry` says to review
  the failed numbered playbook, output, and progress marker first.
- Use the documented completion evidence; do not create or delete progress
  markers manually.

## Special boundary: SPS-level questions

The local docs tell operators to review BOM names, URLs, archive names,
checksums, and target product versions, but they do **not** ship an
SPS07-specific troubleshooting runbook. Use this rule:

- "Which BOM/version do I need for SPS07?" → `sdaf-bom-selection`.
- "The already-selected SPS07 media set is failing with a missing archive,
  checksum, or extract error" → stay here and work the exact failing file/log
  through the symptom map.

## Hard rules

- Documented behaviour only. `docs/PLUGINS.md` explicitly says air-gapped /
  offline media is outside shipped guidance.
- Do not invent new BOM contents, replacement URLs, checksums, or SPS mappings.
- Do not treat a generic later install failure as a media problem without a
  matching acquisition / processing anchor.
- Do not delete `.progress` markers or storage blobs merely to force a rerun.

## See also

- `sdaf-bom-selection` — choose product vs component BOMs and compatibility
  guardrails.
- `sdaf-media-acquisition` — clean first-time media download once the failure
  boundary is gone.
- `sdaf-failure-triage` — non-media or ambiguous stage failures.
- `docs/local/06-00-software-and-installation.md`,
  `docs/local/troubleshooting.md`,
  `docs/PLUGINS.md`.
