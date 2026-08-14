# Correctness and Terraform

Dimension 1 detail. Every shape below is a defect that has been found in review in this
repository, or is derived directly from one.

## 1. The sibling sweep

Do this before anything else. It is the single highest-yield check in this repository.

### The parallel structures

```text
deploy/terraform/
  bootstrap/            sap_deployer  sap_library
  run/                  sap_deployer  sap_landscape  sap_library  sap_system
  terraform-units/modules/
                        sap_deployer  sap_landscape  sap_library
                        sap_namegenerator  sap_system
```

Per-module files that come in parallel sets: `variables_global.tf`, `variables_local.tf`,
`imports.tf`, `providers.tf`, `output.tf`, `tfvar_variables.tf`.

### The wiring chain

A new input must be threaded through every link:

```text
root-module declaration — tfvar_variables.tf OR variables_global.tf
  (one namespace; these are alternatives, never both)
  → module "…" block   (pass into the unit module, possibly transformed)
    → unit variables_local.tf / variables_global.tf
      → the resource that consumes it
```

Terraform merges all root-module `.tf` files into a single namespace, so an input is declared
in **one** of those files — `sa_connection_string` in `tfvar_variables.tf`, `deployers` in
`variables_global.tf`. Asking for a declaration in both requests a duplicate and breaks
`terraform validate`. Locate the single declaration, then follow it through any transform,
across the module boundary, to the resource.

Break a link where the downstream input **has a default** and the deployment **succeeds with
that default** — no error, silent wrong configuration. Where the downstream input has **no**
default, the omission fails `terraform validate` instead, and the wrong outcome is a broken
plan, not a silent misconfiguration. Check which case applies before you name the outcome, then
flag the first link that drops it.

### Contract or defect — the discriminator

Repetition means two opposite things here.

- Repeated thing is **correct in the sibling** → it is the repository's **convention**. Stay
  silent. Constants, naming schemes, and structural patterns that are identical everywhere and
  doing their job are contracts, not duplication.
- Repeated thing is **wrong in the sibling too** → it is **one defect across N sites**. Report
  it **once**, listing every unfixed sibling. Do not open one comment per file.

If you cannot open the sibling, say so and phrase the finding as a question naming the file.

## 2. Identity and idempotency

### Replace-triggering changes

Changing any of these on an existing landscape destroys and recreates the resource. **The cause
determines the remedy**, so classify it before you propose one:

**Group A — Terraform *address* changes.** The remote object is unchanged; only its address in
state moves. A `moved {}` block or `terraform state mv` genuinely fixes these.

| Change | Consequence |
|---|---|
| A resource moved between modules, or its Terraform label renamed | Destroy + create unless the address is migrated |
| A `for_each` **key** | The old key is destroyed, the new one created |
| `count` ↔ `for_each` conversion | The entire collection is re-keyed |

**Group B — provider `ForceNew` *argument* changes.** The remote object's identity changes.
**`moved {}` and `terraform state mv` do nothing here** — they only remap addresses, and the
provider still plans a replace. Requiring one of them is an ineffective mitigation, and
accepting one as sufficient is itself a Blocking-level review error.

| Attribute | Consequence |
|---|---|
| `name` / any `*_custom_name` input | VM, disk, or storage account replaced |
| `resource_group_name`, `location` | Everything in the module moves |
| Subnet `name` or `virtual_network_name` | Subnet replaced, dependent NICs replaced |

Note that subnet `address_prefixes` is **not** `ForceNew` in the pinned AzureRM 4.80.0 schema —
the update path handles `HasChange("address_prefixes")`, so an in-place prefix change is not a
replacement. Do not raise it as one.

Flag any diff that alters how a name is computed — `sap_namegenerator` logic, prefix/suffix
handling, a `*_custom_name` default — or that moves a resource between modules.

**Required in the finding:**

- **Group A** — a `moved {}` block in the diff, or an explicit `terraform state mv` runbook in
  the PR description.
- **Group B** — a replacement and data-migration plan: what is destroyed, what is lost, the
  downtime, and the order of operations. A `moved {}` block does **not** satisfy this.

"It's just a rename" is not an answer; neither is "no one has deployed this yet".

### Ordered-index keys

```hcl
# fragile — inserting an element re-keys everything after it
for_each = { for i, v in var.items : i => v }

# stable — keyed by an intrinsic identifier
for_each = { for v in var.items : v.name => v }
```

## 3. Key Vault secret reads — the narrow rule

Both forms are legitimate and both are in use. `data "azurerm_key_vault_secret"` is by far the
more common. **Do not flag a `data` block on sight** — that finding is wrong and has been
raised before.

The actual constraint: CI (`terraform-checks.yml`) rewrites `ephemeral` to `data` before
running `terraform test`, because `mock_provider` cannot mock an ephemeral resource
(hashicorp/terraform#38608). The rewrite is scoped to:

| Modules | What is rewritten, and where |
|---|---|
| `run/sap_deployer`, `run/sap_landscape`, `run/sap_library`, `run/sap_system`, `bootstrap/sap_library` | the `ephemeral "azurerm_key_vault_secret"` **declaration** — in `imports.tf` only |
| the same modules | `ephemeral.azurerm_key_vault_secret.` **references** — in `providers.tf` and `variables_local.tf` only |

A new `ephemeral` read added **outside those modules** is never swapped. So is a new
**declaration** placed in `providers.tf` or `variables_local.tf`, since those files have only
their references rewritten (`terraform-checks.yml:238-241`). Either breaks `terraform test`.
That is the finding — state it in those terms, naming the file.

## 4. Validation at the boundary

A new variable with a constrained domain — a SKU, a tier, an enum, a CIDR, a SID, an instance
number — needs a `validation {}` block:

```hcl
variable "database_size" {
  description = "..."
  type        = string
  validation {
    condition     = contains(["S4DEMO", "M32ts", "M64s"], var.database_size)
    error_message = "database_size must be one of S4DEMO, M32ts, M64s."
  }
}
```

Without it an invalid value surfaces partway through the apply, leaving a half-built
landscape. Ask for the block **and** an `expect_failures` test (dimension 6) in the same PR.

**`try()`, `can()`, and `coalesce()` that swallow a genuinely-missing required input** and
substitute a default are the same defect wearing a different hat — the deployment proceeds
with a value nobody chose.

## 5. Conditionals, nulls, and counts

- `count = var.x ? 1 : 0` where `var.x` is an optional variable — unset is `null`, not
  `false`, and `null ? … : …` is an error. Require `var.x != null && var.x`, or a `default`.
- A ternary whose branches return types that **cannot unify** — an object and a list, a map and
  a string. Terraform does auto-convert compatible types (a number and a string both unify to
  string), so differing types alone is not a finding; name why these two cannot converge.
- A `local` that references a variable only declared in one root module.
- A `dynamic` block whose `for_each` can be `null` rather than `[]`.

## 6. Provider and version changes

A provider version bump, a `required_providers` change, or a new provider alias affects every
module that inherits it. Check that the constraint is applied consistently across the root
modules, and that a major bump has a note about resource-schema changes.

## 7. State and import semantics

`imports.tf` blocks are load-bearing. An import block whose `id` expression changes shape will
either import the wrong resource or fail the plan — Blocking. **Removing an already-applied
import block is safe** and is the documented cleanup: the resource stays in state. Do not flag
it. Only flag a removed import block whose import has **not** yet been applied everywhere the
configuration is deployed, and say which landscape that is.
