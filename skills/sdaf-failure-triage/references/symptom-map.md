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
| Terraform state lock | `§ Terraform reports a state lock` | Confirm no concurrent run; do not force-unlock |
| Unexpected replacement in plan | `§ Terraform proposes unexpected replacement` | Compare tfvars, provider lock, keys, IDs; stop before approval |
| Control plane stopped partway through | `§ A control-plane run stopped partway through` | `sdaf-control-plane-bootstrap` — use `--recover` only after state agrees |
| Generated `<SID>_hosts.yaml` / `sap-parameters.yaml` missing | `§ Generated Ansible files are missing` | `sdaf-sap-system` — rerun same command |
| BOM files not found | `§ BOM files are not found` | `sdaf-bom-selection` — check `BOM_CATALOG` |
| Workload-zone deploy fails with a private-endpoint / subnet-policy error | `docs/local/04-00-workload-zone.md § Configuration preparation` (owns the exact error string and prescribed setting for the scope it documents) | **`sdaf-workload-zone` — owns the decision boundary** |
| Ansible playbook fails | `§ An Ansible playbook fails` | Inspect first failed task; rerun the smallest applicable playbook |
| Removal reports success but resources remain | `§ Removal is incomplete` | Do not edit state; follow the section's diagnostic path |

## Canonical Government / sovereign-cloud disclaimer

**One canonical statement for the whole plugin.** Sibling skills point here
rather than repeating it.

The shipped local docs cover:

- The Azure Government private-endpoint / subnet-policy workaround
  (`docs/local/04-00-workload-zone.md § Configuration preparation`, owned by
  `sdaf-workload-zone`).
- The Government-region codes (`docs/region-codes.md § Supported regions`
  includes `usgovarizona`, `usgovtexas`, `usgovvirginia`).

They do **not** cover an end-to-end Azure Government deployment procedure —
no shipped section describes `ARM_ENVIRONMENT` end-to-end, Government DNS
zone blocks, Government-specific default VM sizes, or Government identity
setup. Per D19 (documented-only) and open decision D19a, no skill in this
plugin will invent Government-specific behaviour. When an operator asks for
a procedure that fits none of the two documented cases above, say docs are
silent and stop.

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
- Azure Government end-to-end first-run failure modes (see the canonical
  disclaimer above).
- Air-gapped / offline / proxy-blocked flows.
- Any "benign log noise" catalogue.