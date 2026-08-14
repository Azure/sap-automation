# Evidence and Severity

How to decide whether a finding may be posted, and how to word it. This governs every
dimension. When this file and a dimension rule disagree, this file wins.

## Evidence tiers

Every finding carries a tier, stated **explicitly** as the `Evidence:` line of the output block
(`Evidence: Verified` or `Evidence: Probable`) — never post a Verified claim you cannot
support. Word the finding body to match the tier as well.

| Tier | You have | `Evidence:` line | How to word the body |
|---|---|---|---|
| **Verified** | Read the code path end to end, in this diff or in files you opened | `Evidence: Verified` | Direct assertion. `variables_local.tf` never reads `var.new_flag`, so the module deploys with the default regardless of the tfvar. |
| **Probable** | A strong pattern match, but one link is unread | `Evidence: Probable` | Name the unread link. This looks like X; I could not open `run/sap_system/variables_global.tf` to confirm — can you check? |
| **Unverified** | A suspicion | — | **Do not post it.** |

## Hard prohibitions

Violating any of these is worse than missing the finding.

1. **Never invent a line number, symbol, file path, resource name, or error message.** If you
   cannot cite it, describe the location in prose instead.
2. **Never fabricate tool output.** Do not write "checkov flags this" or "tflint will fail"
   unless you have the run's actual output — your guess about a heuristic scanner is not its
   verdict. This does **not** bar you from analysing a **deterministic** gate whose rule you
   read: if you have opened `terraform-checks.yml` and traced that a missing `total_runs`
   update fails the coverage gate, state it — and cite the workflow lines you read. Verified
   analysis of a rule you can quote is evidence; an invented scanner verdict is not.
3. **Never claim a sibling module is unfixed without opening it.** This repository's structure
   makes that assumption tempting and frequently wrong. If you cannot open it, ask a question
   naming the file.
4. **Never assert a standard, SAP note, or vendor prescription you cannot cite.** No citation,
   no finding. This is the most common false positive in HA and cluster reviews here.
5. **Never restate a finding a CI gate has already reported** — checkov 3.3.8, tflint 0.63.1,
   `terraform validate`, the terraform-docs drift check, the coverage gate, pytest,
   ansible-lint. Duplicating a reported failure is noise and it trains reviewers to ignore you.
   This bars *repeating a failure the run already shows*; it does not bar the verified
   deterministic analysis permitted in prohibition 2 — a missing `total_runs` update you traced
   through the workflow is still yours to raise, before any run reports it.
6. **Never propose a formatting-only change.** There is no `terraform fmt -check` in CI, and
   that absence is not a licence — formatting is not a defect and a formatting comment
   displaces a real one.
7. **Never post a finding whose only support is that a value is unusual.** Unusual is not
   wrong. Deployment frameworks are full of prescribed-and-odd-looking values.

## Known false-positive classes

These have been raised and rejected in this repository's review history. Do not raise them
again without new evidence.

| # | Class | Why it is not a finding |
|---|---|---|
| **F1** | Established default called wrong | A long-standing default is a contract. Changing it is a behaviour change; keeping it is not a defect. |
| **F2** | Convention flagged as duplication | Repetition that is correct in every sibling **is** the convention here. See the discriminator in `correctness-and-terraform.md` §1. |
| **F3** | Sovereign-cloud fencing value | `azureusgovernmentcloud` as the Pacemaker fencing cloud is deliberate. |
| **F4** | Prescribed timeout/interval called excessive | Cluster and resource-agent values come from SAP notes and vendor docs. Cite or drop. |
| **F5** | Formatting | See prohibition 6. |
| **F6** | Predicted scanner output | See prohibition 2. |
| **F7** | `data "azurerm_key_vault_secret"` flagged on sight | Both `data` and `ephemeral` forms are legitimate; `data` is the more common. Only a **new ephemeral read outside** the CI-swapped module/file set is a finding. |
| **F8** | Pre-existing wildcard re-litigated | Two unrelated `0.0.0.0/0` sites already exist and are **not** findings: `sap_deployer/firewall.tf:141` is an `azurerm_route.address_prefix` — a **default route**, not an ACL, and correct as written; `hdb_node/anf.tf` lines 41/110/187 are `export_policy_rule.allowed_clients`. Anchor to the **specific resource and line** in the diff: a **newly added** rule is a finding even when an identical value exists elsewhere in the same file. "Widened" cannot apply to `0.0.0.0/0` — it is already maximal — so do not use that word to dismiss a new one. |

## Severity vocabulary

Use exactly these four labels.

| Label | Meaning | Bar |
|---|---|---|
| **Blocking** | Merging causes incorrect deployment, resource replacement, data loss, a leaked secret, or new exposure | Verified evidence only. Name the wrong outcome. |
| **Should fix** | A real defect with bounded consequence, or a Blocking-shaped issue at Probable evidence | Consequence must be stated |
| **Question** | You need information the diff does not contain to decide | Must be answerable from the PR |
| **Nit** | Genuinely optional, no correctness or reliability consequence | Cap at two per review |

Do not use "consider", "might want to", or "it would be nice if" as a severity. They read as
Nit regardless of what follows, and they bury real findings.

Special case: **a change that triggers a resource replace on an existing landscape is
Blocking**, regardless of how small the diff is, until the PR carries the remedy that matches
the cause — a `moved {}` block or state-move runbook for a Terraform **address** change, or a
replacement and data-migration plan for a provider **`ForceNew` argument** change. A `moved {}`
block does not clear a `ForceNew` argument change.

## Volume control

A review with forty comments is not read. Prefer depth over breadth.

- **Cap Nits at two.** Drop the rest.
- **Collapse duplicates.** One repeated defect across N modules is **one** comment listing all
  N sites, not N comments. This matters more here than anywhere else — the parallel module
  structure makes it easy to generate five copies of the same comment.
- **When two findings overlap, keep the one with the more concrete consequence.**
- **If a diff has more than five Blocking findings**, lead the summary with the systemic cause
  rather than enumerating symptoms.

## Actionability

Every comment states three things:

1. **What** is wrong — the specific behaviour, not a category name.
2. **Why** it matters — the concrete wrong outcome, in this system. For infrastructure that
   means: what gets destroyed, what gets exposed, what deploys with the wrong value.
3. **How** to fix it — a corrected snippet, a named alternative, an existing correct example
   from this repository, or a citation.

A comment missing (3) is not ready to post. Prefer citing an existing correct implementation
in a sibling module over describing one in the abstract — it proves the fix fits the codebase
and it is exactly the evidence the author needs.

## The challenge protocol

When an author disagrees:

- **New evidence provided** → say so plainly and withdraw the finding. Do not restate it in a
  softer form.
- **No new evidence** → restate the specific consequence once, more concretely, and stop.
- **A design decision you disagree with but which is defensible** → withdraw. Design authority
  belongs to the author and the maintainers.
- **Never** escalate severity because a finding was disputed.

## Silence is a valid review

If the diff is small, correct, consistent with its siblings, and does not touch identity,
scope, or exposure, say so in one line and post nothing. Manufactured findings on a clean diff
cost more credibility than a missed nit ever will.
