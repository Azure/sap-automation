---
name: sdaf-media-acquisition
description: >
  Acquire approved SAP media into the SDAF library after SAP-system
  infrastructure exists. Drives local `deploy/ansible/download_menu.sh` per
  `docs/local/06-00-software-and-installation.md § Download software`,
  enforces the documented `BOM_CATALOG` root and the four required
  `sap-parameters.yaml` BOM keys (`application_bom_name`,
  `database_bom_name`, `sap_kernel_bom_name`, `save_bom_as`), and explains
  the documented download and validation flow. Use for
  "download SAP media", "run download_menu.sh", "acquire software into the
  library", "BOM Downloader", "BOM_CATALOG", or
  "assemble application/database/kernel BOMs for download". Do NOT use to
  choose a BOM, troubleshoot a failed download, or run installation
  playbooks.
allowed-tools: shell
license: MIT
---

# SDAF Media Acquisition

Action-loop skill. Acquires approved SAP media into the library after
SAP-system infrastructure exists. The local operator path is documented in
`docs/local/06-00-software-and-installation.md`; shared downloader behavior
is described in the same operator guide.

## When to invoke

Trigger on: "download SAP media", "acquire software into the library",
"download_menu.sh", "BOM Downloader", "BOM_CATALOG", or
"assemble application/database/kernel BOMs for download".
Do NOT trigger on: choosing a BOM (`sdaf-bom-selection`), troubleshooting a
failed or mismatched download (`sdaf-media-diagnostics`), or install playbooks.

## Preconditions

- SAP-system infrastructure already completed; `sap-parameters.yaml` and
  `<SID>_hosts.yaml` exist in the system directory
  (`docs/local/06-00-software-and-installation.md § Before you begin`; `docs/local/05-00-sap-system.md § Validate`).
- SSH connectivity to the inventory hosts, Key Vault-generated credentials, SAP
  download credentials, and library capacity are confirmed
  (`docs/local/06-00-software-and-installation.md § Before you begin`).
- The BOM choice is already reviewed; this skill does not decide product versus
  component BOMs (`sdaf-bom-selection`; `sap-automation-samples/docs/02-00-bom-samples.md § Select and run a BOM`).

## Decision: which download input shape applies?

`docs/local/06-00-software-and-installation.md § Inputs and BOM ownership` is
explicit:
- `BOM_CATALOG` must point at the samples checkout root that contains sibling
  `SAP/` and `BOM/` directories.
- Local `download_menu.sh` does **not** keep the Terraform-generated
  `bom_base_name`. It reads these four keys from `sap-parameters.yaml` and
  constructs the effective BOM name itself:

```yaml
application_bom_name: <APPLICATION_BOM>
database_bom_name:    <DATABASE_BOM>
sap_kernel_bom_name:  <KERNEL_BOM>
save_bom_as:          <COMBINED_BOM_NAME>
bom_base_name:        <COMBINED_BOM_NAME>
```

Keep these values in the exact format documented by
`§ Inputs and BOM ownership`. The automation validates the application,
database, kernel, and output-name combination before download. Require
`bom_base_name` to equal `save_bom_as`; installation reloads
`bom_base_name` and must find the combined BOM written by the downloader.

## Recipe

### Step 1 — Confirm the catalog root and component names

From the SAP-system directory, confirm the catalog root exactly as the local
doc requires:

```bash
cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
test -d "$BOM_CATALOG/SAP"
test -d "$BOM_CATALOG/BOM"
```

Then re-read `sap-parameters.yaml` once. For the local menu path, all five BOM
keys above must be present, component names must match actual samples
directories/files, and `bom_base_name` must equal `save_bom_as`.

### Step 2 — Run the documented local acquisition flow

Start the local wrapper exactly per
`docs/local/06-00-software-and-installation.md § Download software`:

```bash
"$SAP_AUTOMATION_REPO_PATH/deploy/ansible/download_menu.sh"
```

Then select **BOM Downloader**. The documented path requires
`sap-parameters.yaml` in the current directory and `BOM_CATALOG` in the
environment.

### Step 3 — Validate before installation

Do not continue into `configuration_menu.sh` until both doc-level checks pass
(`docs/local/06-00-software-and-installation.md § Validate`):
- the downloader reports success for every required archive; and
- the SAP library contains the expected software.
Also keep the samples commit and selected BOM names with the run record
(`sap-automation-samples/docs/02-00-bom-samples.md § Validate`).

## If the run stops or rejects the input

- `sap-parameters.yaml` missing, `BOM_CATALOG` unset, or `BOM_CATALOG` not a
  directory: fix the local wrapper precondition and rerun
  (`deploy/ansible/download_menu.sh`;
  `docs/local/troubleshooting.md § BOM files are not found`).
- Incompatible application/database/kernel combination: go back to
  `sdaf-bom-selection` and review the documented compatibility fields.
- Archive, checksum, or download-service failures belong to
  `sdaf-media-diagnostics`, not this skill.

## Hard rules

- Documented behaviour only (D19). Do not invent alternate download
  commands, proxy/offline procedures, or compatibility matrices (`docs/PLUGINS.md § Ground rules and exclusions`).
- Do not point `BOM_CATALOG` at a single BOM directory.
- Do not bypass checksum or compatibility failures
  (`sap-automation-samples/docs/02-00-bom-samples.md § If it fails`).
- Do not start installation until the downloader reports success for the
  required archives.

## See also

- `sdaf-bom-selection`, `sdaf-sap-system`, `sdaf-media-diagnostics`.
- `docs/local/06-00-software-and-installation.md`,
  `docs/local/troubleshooting.md § BOM files are not found`,
  `sap-automation-samples/docs/02-00-bom-samples.md`,
  [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).
