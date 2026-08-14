# Reliability and Security

Dimensions 2 and 3 detail.

---

# Dimension 2 — Reliability / SRE

The deployer shell scripts and the Ansible roles are the control plane for production SAP
landscapes. A step that reports success after failing leaves a landscape in an unknown state,
and the next step builds on top of it.

## Shell scripts

### `pipefail` before any pipeline that matters

```bash
# wrong — exit status is tee's, which is 0 almost always
terraform apply -auto-approve | tee "${log}"
if [ $? -ne 0 ]; then …    # never true

# right
set -o pipefail
terraform apply -auto-approve | tee "${log}"
```

`set -e` alone does **not** cover pipelines, command substitutions, or commands in an `if`
condition. State that explicitly when you raise it.

### Check the status of every consequential call

Every `az`, `terraform`, and `ansible-playbook` invocation whose failure should stop the run
needs its exit status checked — or `set -e` plus `pipefail` and no `|| true`.

### Validate before the first side effect

A script that provisions and *then* discovers a bad parameter leaves half a landscape and a
dirty state file. All parameter validation belongs before the first `az`/`terraform` write.

### One inconsistent line among N identical blocks

The deployer scripts contain long runs of near-identical blocks. A single line that differs —
a missing redirect, a missing `--no-wait`, an extra echo of a variable — is a finding. That is
how a credential once reached a log.

### Re-run safety

A script that fails midway must be safe to re-run. Flag:

- unconditional appends to a file that is read later;
- `create` without an existence check;
- a counter or an accumulated variable incremented outside a guard;
- a temp file or lock that is not cleaned up on the failure path.

## Ansible

| Pattern | Why it is a finding |
|---|---|
| `failed_when: false` / `ignore_errors: true` where the failure is **never interpreted** | Turns a failure into a false negative. A state probe that suppresses the status so it can branch on `rc` — `1.17.1-pre_checks.yml:132-140` — is correct. So are best-effort cleanup and `rescue`; say which applies |
| `when: x is defined` / `\| default([])` with no preceding `assert` | A **missing** fact becomes a **skipped** check rather than an error |
| `retries` / `delay` with a multi-minute worst case | Ask what condition would let it exit sooner |
| A cluster-mutating block with no `rescue` | A mid-block failure leaves the cluster in a transient state |
| `changed_when` omitted on a `shell`/`command` task **that does not always mutate** | A read-only or conditionally idempotent command reports changed every run, masking real drift. A command that genuinely changes state on every run — `crm resource cleanup` in `1.17.2.0-cluster-Suse.yml` — is correct without it. Do not flag that |

## Failure blast radius

State it in the finding. "This fails" is weaker than "this leaves the ASCS resource group
partially created and the next run fails on the existing storage account."

---

# Dimension 3 — Security

## Shell injection

`eval` is used pervasively in this repository: **21 of the top-level scripts directly under
`deploy/scripts/` contain one** (31 across `deploy/scripts/` recursively, including
`helpers/` and `pipeline_scripts/`), including the entire parallel `*_v2.sh` generation. A
representative sample:

```text
deploy/scripts/installer.sh            deploy/scripts/installer_v2.sh
deploy/scripts/deploy_controlplane.sh  deploy/scripts/deploy_control_plane_v2.sh
deploy/scripts/install_deployer.sh     deploy/scripts/install_deployer_v2.sh
deploy/scripts/install_library.sh      deploy/scripts/install_library_v2.sh
deploy/scripts/remove_controlplane.sh  deploy/scripts/remove_control_plane_v2.sh
deploy/scripts/remover.sh              deploy/scripts/remover_v2.sh
deploy/scripts/set_secrets.sh          deploy/scripts/set_secrets_v2.sh
deploy/scripts/deploy_utils.sh         deploy/scripts/sync_deployer.sh
deploy/scripts/validate.sh             deploy/scripts/install_workloadzone.sh
deploy/scripts/advanced_state_management.sh
```

**This list is illustrative, not exhaustive.** Treat *every* `eval` under `deploy/scripts/` as
a live injection sink and re-derive the affected sites from the diff — a script's absence from
this list is not evidence that it is out of scope. The `_v2` scripts are the newer deployment
path and are exactly as exposed as the originals.

Any diff that routes a new parameter, a filename, an environment value, or a `tfvars`-sourced
value into **any** of those paths — or that adds a new `eval` — is a finding.

Rules:

- Validate the **completed** command, not a fragment assembled earlier.
- **Allow-list, not deny-list.** A deny-list of dangerous characters is not a control.
- Prefer an argument array over a constructed string.
- The same applies to an Ansible `shell:` task interpolating a variable that originates
  outside the repository — but only where the interpolation is **unescaped**. Ansible's
  `| quote` filter shell-escapes the value and is a valid mitigation; a quoted interpolation is
  not a finding. Prefer `command:` with `argv` where the task needs no shell feature, and
  `shell:` with `| quote` where it genuinely needs a pipe or redirection.
  `ansible.builtin.command` does **not** run through a shell, so
  metacharacters in an interpolated value are not interpreted as commands — distinguish it.
  For `command:` the risk is executable or argument manipulation; the remedy is `argv`, and
  the finding requires showing how the argument boundary breaks.

Name the concrete injecting input. Without one the finding is Probable at best.

## RBAC scope

`terraform-units/modules/sap_deployer/role_assignments.tf` grants roles at **two different
scopes**, and the distinction matters:

| Scope | Assignment | Actual role |
|---|---|---|
| Subscription | `subscription_contributor_msi` | Contributor |
| Subscription | `subscription_useraccessadmin_msi` | User Access Administrator |
| Subscription | `subscription_contributor_system_identity` | **Reader** — despite the name |
| Resource group | `resource_group_user_access_admin_msi` | User Access Administrator |
| Resource group | `resource_group_user_access_admin_spn` | Role Based Access Control Administrator |

The table is a **non-exhaustive escalation checklist**, not an inventory. The same file also
grants resource-group Contributor, Reader, and Network Contributor, and resource-scoped Key
Vault, storage, and App Configuration roles. Read the `scope`, `role_definition_name`, **and
`condition` / `condition_version`** of every assignment the diff touches; an assignment missing
from this table is not absent. The User Access Administrator and RBAC Administrator grants
carry ABAC `condition` blocks (`role_assignments.tf:117-138`, `155+`); removing or broadening
one escalates privilege without changing role or scope at all.

**Read `role_definition_name`, never the resource name.**
`subscription_contributor_system_identity` is assigned `"Reader"` at
`role_assignments.tf:54-59`. A diff that changes that value to `Contributor` is a
subscription-scope privilege escalation that the resource name makes almost invisible.

Note the scope split too: RBAC Administrator is **resource-group** scoped today. A diff that
promotes a resource-group assignment to subscription scope is an escalation, and it is exactly
the change a reviewer misses when they believe the broader grant already exists.

**Scrutinise — but do not automatically flag —** a diff that:

- adds an `azurerm_role_assignment`;
- widens an existing `scope` — resource → resource group → subscription;
- introduces a new secret where a managed identity would work.

**The finding** is excess privilege or excess scope: a role broader than the resources the
module owns, or a scope wider than those resources occupy. An added assignment that is
least-privileged and required is not a defect — say nothing.

The finding must name **the role, the scope, and what it now reaches**. "Least privilege" as a
phrase is not a finding.

## Network exposure

Existing wildcards — do not re-litigate these lines, and note what each one *is*:

```text
sap_deployer/firewall.tf:141   address_prefix = "0.0.0.0/0"  → azurerm_route to a
                               VirtualAppliance. This is a forced-tunnel default route, a
                               security *control*, not exposure. Never flag it as exposure.
sap_deployer/firewall.tf       ["*"] in a firewall rule collection
sap_system/hdb_node/anf.tf     allowed_clients = ["0.0.0.0/0"]
```

**Scope this rule to access-control resources.** A wildcard is only exposure in an NSG rule, a
firewall network/application rule, an ANF export policy, or a storage-account or Key Vault
network ACL. A `0.0.0.0/0` in an `azurerm_route`, a UDR, or a default-route table is routing —
flag it only if the `next_hop_type` change *removes* an inspection hop.

**Do** flag a diff that **adds** a wildcard to one of the access-control resources above, or
that widens:

- an NSG rule's source prefix, destination, or port range;
- a firewall network or application rule;
- an ANF export policy's `allowed_clients`;
- a storage-account or Key Vault network ACL.

## Permissiveness drift

`sap_landscape/storage_accounts.tf` parameterises `public_network_access_enabled` and the
firewall `default_action`. A change to the **default value** of one of these — or to a default
in `tfvar_variables.tf` — silently reconfigures **every landscape that does not override it**.

That is the sentence to put in the finding. A default change is a fleet-wide change.

Flag defaults moving in the permissive direction: `false → true` on public access,
`Deny → Allow` on a default action, a narrower CIDR becoming wider, TLS minimum lowered,
`https_traffic_only` disabled, soft-delete or purge-protection disabled.

## Secrets

- `sensitive = true` on every variable or output carrying a secret, key, password, or
  connection string. **A secret in an output is stored in state in cleartext.** Terraform
  redacts a `sensitive` output from normal CLI output — it is *not* "printed to the console" —
  but `terraform output -raw` / `-json` and the state file itself both expose the value. State
  those two risks separately; conflating them manufactures a leak finding.
- `no_log: true` on Ansible tasks handling credentials.
- No secret in a log line, a captured stdout, an exception message, or telemetry.
- When a diff changes an environment-filter or credential-exclusion list, check **every**
  caller — each script is injected with a different set, so each list must be checked against
  its own caller. A secret added to one list and not its siblings is exactly this defect.

## What the scanners already own

| Gate | Version | Scope |
|---|---|---|
| `checkov` | 3.3.8 | Terraform misconfiguration policies |
| `tflint` | 0.63.1 | Terraform lint rules, provider schema checks |

**Do not restate a finding either tool reports.** Its output is authoritative; your prediction
is not. Never write "checkov catches this" without the run output.

**But note the tflint asymmetry.** CI invokes it as
`tflint … --minimum-failure-severity=error`, so a tflint **warning** is reported in the log and
does **not** fail the build. A warning-severity issue is therefore *not* owned by a gate — it
is review territory. Treat it the way you treat a bandit-LOW in the sibling repository: raise
it, at Should-fix or below, and say that CI reports but does not enforce it. Only
error-severity tflint findings are off-limits as duplicates.

Focus instead on what they cannot see:

- whether a wildcard is *newly introduced* by this diff versus pre-existing;
- whether a **default** change widens exposure fleet-wide;
- RBAC **scope semantics** — the role is valid, the scope is the defect;
- a secret flowing into a log or an output through code paths, not through a policy-checkable
  attribute.

## CI and workflow security

Workflow files under `.github/workflows/` are executable, privileged code — and no Terraform
scanner reads them. Review them as such.

| Check | What to flag |
|---|---|
| Action pinning | A new `uses:` pinned to a **tag or branch** rather than a full commit SHA. A tag is mutable. |
| Trigger | `pull_request_target` or `workflow_run` **combined with a checkout of the PR head** hands fork-authored code a privileged token. There are none today; a new one is Blocking. |
| `permissions:` | For a **new workflow file**, a missing top-level `permissions:` block (inheriting the repo default). For an **existing** workflow, a top-level block that grants more than before — it widens every job that does not override it, a repository-wide escalation. A job-level block is **not** a finding merely because it exceeds the workflow default: that is the intended way to give one job a narrow capability, as `codeql.yml` does with `security-events: write`. Flag a job-level grant only where you can show the effective permission exceeds what that job does. A job with no block inherits the workflow-level block, which is already restrictive here — `terraform-checks.yml` jobs do exactly that. Do not flag that. Compute each job's **effective** permission from both levels, and name it. |
| Untrusted interpolation | A **contributor-controlled** `github.event.*` field interpolated directly into a `run:` block is script injection — `…pull_request.title`, `…body`, `…head_ref`, comment text. Require an intermediate `env:` variable. GitHub-generated fields in the same namespace (numbers, SHAs, enums) cannot carry shell syntax; say who controls the value before calling it injection. |
| Terraform output | `terraform plan`/`apply` output uploaded as an artifact or echoed unmasked — plan output routinely contains resolved secret values. |
| Dependency pinning | A new unpinned `pip install`, `ansible-galaxy install`, or `terraform` version in a workflow. |

## Privilege escalation in Ansible

There are ~1,570 `become` references across `deploy/ansible/`, so **`become` on its own is not
a finding** — do not re-litigate the baseline. Flag the deltas:

- `become: true` added to a task or block that did not have it, with no stated reason;
- `become_user:` changed, especially to `root` or to an `<sid>adm` account it was not before;
- a **new** `NOPASSWD` sudoers entry, or a widened one — name the exact command allowed;
- `become` on a task running a command built from an interpolated variable — that combines the
  injection rule above with root, and is Blocking;
- a `become` block that widened in scope because a task moved inside it.

## Transport and host-key verification

`ANSIBLE_HOST_KEY_CHECKING=False` and `ssh -o StrictHostKeyChecking=no` are already pervasive —
`deploy/scripts/configure_deployer.sh:727`, `deploy/scripts/deploy_control_plane_v2.sh:802`, the
`SDAF-General` variable group in `create_devops_artifacts.sh:179`, and others. That is the
existing baseline; do not raise it as new.

Flag anything that **extends** the weakening:

- a **new** `StrictHostKeyChecking=no`, `UserKnownHostsFile=/dev/null`, or
  `ANSIBLE_HOST_KEY_CHECKING=False` in a connection path that did not have one — especially a
  new `_v2` script inheriting it by copy;
- `validate_certs: false` on an Ansible module, `verify=False` on a Python request, or
  `curl -k` / `wget --no-check-certificate`;
- a storage account, Key Vault, or App Service diff that lowers `min_tls_version`, enables
  `allow_nested_items_to_be_public`, or sets `https_only = false`.

## Deserialization and command execution

- `yaml.load` without a safe loader, `pickle.load`, `marshal`, or `exec` on a non-literal.
- `jq`/`sed`/`awk` output fed straight into `eval` — see the shell-injection section; the
  `deploy/scripts/` `eval` sites are the concrete sinks.

## Secrets in logs and artifacts

Beyond the `no_log` rule above:

- a command run under `set -x` while a secret is in its arguments or environment;
- a secret written into an uploaded artifact, a `terraform plan` file, a `tfvars` file
  committed to the repo, or a captured `stdout` that is later logged;
- a credential file created without restrictive permissions, or left behind after use;
- a new secret-bearing environment variable not added to the existing credential-exclusion
  list — and check **every** caller, per the rule above.
