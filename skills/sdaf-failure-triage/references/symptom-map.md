# Failure symptom map (documented)

Companion to `sdaf-failure-triage`. Every row cites
`docs/local/troubleshooting.md` unless another doc is named. Rows without a
documented anchor are deliberately absent (D19).

## Symptom → documented anchor → hand-off

| Observed symptom | Documented section | Hand-off |
|---|---|---|
| Script fails immediately; env var missing | `§ A required export is missing` | Export vars; re-run the invoking skill |
| "Parameter file not found" | `§ A parameter file is not found` | Re-run from the tfvars' directory; basename only |
| Terraform / Azure CLI missing | `§ Terraform or Azure CLI is not found` | `sdaf-readiness-check` (`docs/local/02-00-prepare-execution-environment.md § Readiness verification` step 1) |
| Azure auth / authorization failure | `§ Azure authentication or authorization fails` | Fix identity outside SDAF; do not grant broad roles |
| Host cannot reach Key Vault / Storage | `§ The execution host cannot reach Key Vault or Storage` | `sdaf-readiness-check` (`§ Readiness verification` step 3) |
| Terraform state lock, reviewed `state list/import/remove`, or remote-state drift | `§ Terraform reports a state lock`; `docs/local/07-00-operations.md § Manage state safely` | `sdaf-state-management` |
| Unexpected replacement in plan | `§ Terraform proposes unexpected replacement` | Compare tfvars, provider lock, keys, IDs; stop before approval |
| Control plane stopped partway through | `§ A control-plane run stopped partway through` | `sdaf-control-plane-bootstrap` — use `--recover` only after state agrees |
| Generated `<SID>_hosts.yaml` / `sap-parameters.yaml` missing | `§ Generated Ansible files are missing` | `sdaf-sap-system` — rerun same command |
| BOM files not found before or during the downloader path | `§ BOM files are not found` | `sdaf-media-acquisition` — check `BOM_CATALOG`, the four BOM keys, and the reviewed samples checkout |
| Downloader `404`, checksum mismatch, `SAPCAR` / `.EXE` extract failure, or missing `.progress/bom-processing-done` | `docs/local/06-00-software-and-installation.md § Download software`; `§ Run configuration and installation` | `sdaf-media-diagnostics` |
| Workload-zone deploy fails with a private-endpoint / subnet-policy error | `docs/local/04-00-workload-zone.md § Configuration preparation` (owns the exact error string and prescribed setting for the scope it documents) | **`sdaf-workload-zone` — owns the decision boundary** |
| Numbered install playbook fails after media is staged | `§ An Ansible playbook fails` | `sdaf-sap-installation` — capture the first failed numbered playbook, host, and `.progress` marker |
| Live or recent HA cluster is unhealthy (`crm` / `pcs`, fencing, placement, HCMT evidence) | `docs/local/07-10-quality-assurance.md`; shipped Pacemaker/QA roles | `sdaf-ha-diagnostics` |
| Removal reports success but resources remain | `§ Removal is incomplete` | `sdaf-safe-removal` — do not edit state; follow the section's diagnostic path |
| Azure Government / sovereign-cloud values, `AADSTS900382`, Government DNS zones, or Government-only workload-zone policy deltas | `docs/region-codes.md § Supported regions`; `docs/local/04-00-workload-zone.md § Configuration preparation`; `skills/sdaf-sovereign-cloud/references/documented-cloud-boundaries.md` | `sdaf-sovereign-cloud` |

## Sovereign-cloud hand-off

`sdaf-sovereign-cloud` is the canonical owner for the currently documented
Azure Government deltas:

- Government region codes (`usgovarizona`, `usgovtexas`, `usgovvirginia`);
- Government-only GitHub OIDC / `ARM_ENVIRONMENT` / `AZURE_ENVIRONMENT` /
  `AZURE_AUDIENCE` combinations and their documented failure signatures;
- Government `dns_zone_names` handling; and
- the Government-only workload-zone private-endpoint policy workaround.

If the operator asks for an end-to-end Government, China, German, or other
sovereign procedure beyond those cited deltas, `sdaf-sovereign-cloud`
itself stops and says the current sources are silent.

## Canonical "clean plan reported as failure" note

There is no shipped section named "clean plan reported as failure". When an
operator reports this symptom:

- Walk the stage's `§ Validate` and `§ Outcome` checks first
  (`docs/local/03-00-control-plane.md`, `04-00-workload-zone.md`,
  `05-00-sap-system.md`).
- Then check `§ Terraform proposes unexpected replacement` and (for the
  control plane) `§ A control-plane run stopped partway through`.
- If neither matches, say docs are silent on a general "false failure on a
  clean plan" class and stop.

## Deliberately absent (docs silent)

- A general shipped section for "false failure on a clean plan" (see the
  note above for what to do instead).
- Undocumented sovereign-cloud procedures beyond the published
  `sdaf-sovereign-cloud` boundaries.
- Air-gapped / offline / proxy-blocked flows.
- Any "benign log noise" catalogue.