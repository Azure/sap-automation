# Domain, Performance, and Testing

Dimensions 4, 5 and 6 detail.

---

# Dimension 4 — Azure / SAP Domain Rules

This is the dimension a general-purpose reviewer cannot cover. Prefer a domain finding over a
generic one when both apply.

## Half a matrix is a defect

A change that handles one axis value and not the other is a defect even when it is correct for
the value it handles.

| Axis | Values that must both be handled |
|---|---|
| Distribution | SUSE (`crm`, `crm_mon`) / RHEL (`pcs`, `pcs status`) |
| HANA topology | Scale-Up / Scale-Out HSR / Scale-Out with Standby |
| Cluster provider | `SAPHanaSR` / `SAPHanaSR-angi` |
| Stack | HANA DB / ASCS-ERS (SCS) |
| Fencing | SBD / Azure Fence Agent |
| Deployment | Single-zone / zonal / cross-zone |

Name the missing branch and the file that would hold it. "Handled elsewhere" needs a file
path. If the diff adds a value to one of these axes, every consumer of the axis is in scope.

## Resource-agent and cluster parameters

Timeout, interval, monitor, migration-threshold, and `PREFER_SITE_TAKEOVER`-style values are
**prescribed** by SAP notes, resource-agent documentation, or Microsoft Learn. They routinely
look wrong against general best practice and are correct anyway.

**Cite the source or do not raise it.** "This timeout looks high" with no citation is not a
finding — it is one of the recurring false positives in this repository.

## Sovereign clouds

Hardcoded `core.windows.net`, `login.microsoftonline.com`, `vault.azure.net`, or a management
endpoint assumed from the public cloud is a defect for US Gov and China deployments. Check
storage suffixes, ARM audiences, and Key Vault DNS suffixes.

**Do not flag `azureusgovernmentcloud`** as the Pacemaker fencing cloud value — it is a
deliberate contract in this framework and has been raised and rejected repeatedly.

## Naming, sizing, and quota contracts

- SAP SID: 3 alphanumeric, first character alphabetic, not a reserved SID.
- Instance number: 2 digits, unique per host.
- Hostname length limits differ by OS and by SAP component.
- VM SKU: check availability **and zonal support** in the target region before calling a new
  default correct. A SKU that exists in `westeurope` may have no zones in the target region.
- Disk count and IOPS limits are SKU-bound; a new disk layout must fit the SKU's limits.

## Storage and disk semantics

Disk type, caching mode, and write-accelerator settings for HANA **data** and **log** volumes
follow SAP on Azure guidance, not general Azure defaults — e.g. log volumes and caching have
prescribed combinations. A change to any of these needs a citation.

ANF service level and volume size interact (throughput is provisioned from size on some tiers)
— a size reduction can be a performance regression.

## Idempotency in HA operations

A playbook that migrates, fences, or fails over a resource must leave the cluster in a known
state whether it succeeded or failed. Cleanup that only runs on success is a defect.

---

# Dimension 5 — Performance

Report the **consequence** — added minutes, N× the forks, a serialised play — not the shape
alone.

## Per-item shell in a loop

```yaml
# one fork per item — pattern at
# deploy/ansible/roles-os/1.5-disk-setup/tasks/1.5-custom-disks.yml
- name: Create filesystem
  community.general.filesystem:
    dev: "{{ dev_path_from_lv_item }}"
  loop: "{{ custom_logical_volumes }}"
```

A `shell`/`command` inside `loop`/`with_items` over discovered devices, disks, or files costs
one process fork and one SSH round trip per item — `with_items: "{{ sd_devices.stdout_lines }}"`
and `"{{ azure_scsi_devices.stdout_lines }}"` in the fstab UUID-conversion tasks are the shape
to watch. On a system with many devices this dominates the role. Prefer a single script that
emits structured output, or a batched form.

## Controller serialisation

```yaml
# serialises the whole play on the controller
delegate_to: localhost
run_once: true
loop: "{{ hosts }}"
…
- ansible.builtin.wait_for: …
```

Pattern at `deploy/ansible/roles-db/4.0.1-hdb-hsr/tasks/4.0.1.3-copy_ssfs_keys.yml`. Flag a **new**
occurrence; suggest a batched transfer or an async form with a single poll.

## Long polls

`retries: 12 / delay: 10` in the Pacemaker roles is a two-minute worst case per occurrence.
A new one on a common path needs a justification, or a faster exit condition (poll a specific
resource state rather than a fixed count).

## Fact gathering and repeated lookups

- `gather_facts: true` on a play that uses no fact — gathering costs a round trip per host.
- The same `az` or `command` lookup repeated across tasks rather than `register`ed once.
- A `data` source or an `az` call inside a loop that could be hoisted out.

## Terraform plan and apply cost

- A `for_each` over a large computed collection expands the graph and the plan.
- An explicit `depends_on` added where an implicit reference expresses the same ordering
  serialises a graph that could run in parallel — flag it.
- A `data` source that forces a refresh on every plan where a variable would do.

---

# Dimension 6 — Testing Coverage

## Per-module Terraform tests

There are 22 `*.tftest.hcl` files in this repository and **every one is root-level**. All five
unit modules — `sap_deployer`, `sap_landscape`, `sap_library`, `sap_namegenerator`,
`sap_system` — have **zero** tests of their own.

A change to a unit module should add or extend a test for **that module**, not rely on a
root-level test to cover it transitively. Say that explicitly; the gap is structural, not
accidental.

## The shard manifest is part of the test

`terraform-checks.yml` runs a `coverage-gate` that enforces two things:

1. every `*.tftest.hcl` file appears in a `shard-manifest.json`;
2. each manifest's **top-level** `total_runs` equals the **sum** of `run "` blocks across
   **all** of that module's `*.tftest.hcl` files — not a per-file count.

The manifest shape is:

```json
{ "module": "...", "shards": [ { "file": "...", "runs": 15 } ], "total_runs": 56 }
```

The per-file `shards[].runs` values are **not** checked by the gate. Do not raise a finding
that a `shards[].runs` value is stale — it is unverified by design. The number the gate
compares is `total_runs`, and it is derived the way the workflow derives it:

```bash
grep -c '^\s*run "' <module>/tests/*.tftest.hcl | awk -F: '{s+=$NF} END {print s}'
```

**A new test file, or a new `run` block in an existing file, that does not update that module's
`total_runs` fails CI.** Check both in the same diff — this is a mechanical check you can
perform reliably, so perform it.

## Negative tests for new validation

A new `validation {}` block needs an `expect_failures` test proving it rejects a bad value.
The suite already uses `expect_failures` heavily — point at that convention rather than
describing it in the abstract.

Same for a new `precondition` or `lifecycle` guard.

## There is no molecule harness

A passing `ansible-lint` is **style, not behaviour**. A behavioural change to a role has no
automated coverage in this repository.

When a diff changes role logic, say so explicitly and ask for one of:

- a manual validation note in the PR description naming the system it was run against;
- a walkthrough in the PR of the changed tasks and the states they produce.

Do not treat lint as evidence, and do not silently accept an untested role change.

## Tests changed alongside behaviour

If a diff changes behaviour and updates a test's expected value in the same commit, verify the
new expectation is derived from the requirement and not from the new output. An expectation
updated to match observed output is not a test.

## Matrix parity in tests

A change to a platform-matrix feature (dimension 4) needs test coverage for each supported
combination, or the matrix rule is unenforceable. Where the test framework cannot express the
combination, say so and ask for the manual validation note instead.
