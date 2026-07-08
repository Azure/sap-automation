# Copilot Instructions — SAP Deployment Automation Framework (SDAF)

## Project overview

SDAF is Microsoft's open-source framework for deploying and configuring SAP
landscapes on Azure. It provisions infrastructure with **Terraform** and
configures the OS/database/SAP application layers with **Ansible**, driven
from Azure DevOps/GitHub Actions pipelines, from a **.NET web app**
(`Webapp/`) that manages deployment configuration, or via **localized script
execution** — running the `deploy/scripts/` entry points (e.g.
`install_deployer.sh`, `installer.sh`, `deploy_controlplane.sh`) directly from
a shell, without any pipeline or the Webapp involved. Consumers are SAP
Basis/infra teams standing up dev/QA/prod SAP systems (HANA and AnyDB) across
any Azure region. See `docs/repository_overview.md` for the full architecture,
module map, and data flow.

The Webapp subdirectory has its own
`Webapp/.github/copilot-instructions.md` for Azure-tool usage rules — those
apply only when working under `Webapp/`; this file covers the rest of the repo
and general cross-cutting rules.

## Strict requirement: follow official best practices

For every technology in this repo, changes must follow the **official best
practices from that technology's own documentation** — not conventions
inferred from blog posts, Stack Overflow, or general training knowledge.
Concretely:

- **Terraform / HashiCorp**: follow the official
  [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
  and [Terraform language style guide](https://developer.hashicorp.com/terraform/language/style)
  for module structure, resource design, and testing (`terraform test`)
  patterns, reconciled with this repo's documented conventions below.
- **AzureRM / AzAPI providers**: follow the
  [AzureRM provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
  and [AzAPI provider docs](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
  for resource arguments and upgrade guidance.
- **Ansible**: follow the official
  [Ansible best practices guide](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
  and [ansible-lint documentation](https://ansible.readthedocs.io/projects/lint/).
- **Python**: follow [PEP 8](https://peps.python.org/pep-0008/) and the
  official [Black documentation](https://black.readthedocs.io/) for
  formatting, and official [pytest](https://docs.pytest.org/) /
  [pytest-cov](https://pytest-cov.readthedocs.io/) docs for test/coverage
  conventions.
- **.NET / ASP.NET Core**: follow official
  [Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/) guidance.
- **Azure services**: follow official Azure best practices — when Azure MCP
  tools are available (see `Webapp/.github/copilot-instructions.md`), invoke
  `azmcp_bestpractices_get` before generating Azure-related code.

When a claim about "what the docs say" matters, verify it by fetching and
reading the actual current documentation page rather than relying on memory
or a search-result snippet — do not assert a documented value or practice
without a direct quote from the source.

## Tech stack

- **Terraform** (`deploy/terraform/`) — Azure infrastructure. Providers:
  `azurerm`, `azapi`. Pinned versions live in each module's `providers.tf`;
  check that file rather than assuming a version here, and update it (not
  this doc) when bumping providers.
- **Ansible** (`deploy/ansible/`) — OS, database, and SAP application
  configuration, driven by numbered playbooks.
- **ASP.NET Core / .NET 9.0** (`Webapp/`) — configuration UI backed by Azure
  Table Storage.
- **Bash / PowerShell / Python** (`deploy/scripts/`) — deployment orchestration
  scripts invoked by pipelines or run manually.
- **Azure DevOps pipelines** (`deploy/pipelines/`) and **GitHub Actions**
  (`.github/workflows/`) for CI/CD and linting/testing.

## Critical rule: never run `terraform fmt`

This repo intentionally uses **wide, column-aligned `=` signs** in all `.tf`
files (not the default tight alignment `terraform fmt` produces). Do **not**
run `terraform fmt` or any auto-formatter on Terraform files — it will
destroy the existing alignment and produce massive unrelated diffs. When
editing `.tf` files by hand, match the surrounding alignment style.

## Terraform conventions (`deploy/terraform/`)

- Root (entry-point) modules live under `run/{sap_deployer,sap_library,
  sap_landscape,sap_system}` and `bootstrap/{sap_deployer,sap_library}`.
  Reusable child modules live under `terraform-units/modules/` and are
  referenced by relative path from root modules.
- Each root module follows a consistent file layout: `module.tf`,
  `providers.tf`, `backend.tf`, `variables_global.tf`, `variables_local.tf`,
  `tfvar_variables.tf`, `transform.tf`, `output.tf`, `imports.tf`. Put
  complex/derived logic in `variables_local.tf`, not inline in resources.
- Use underscores, not hyphens, in Terraform identifiers (hyphens are fine
  inside actual Azure resource names/strings).
- Known provider aliases: `azurerm.main`, `azurerm.dnsmanagement`,
  `azurerm.privatelinkdnsmanagement`, `azapi.restapi`.
- Validate changes with (no state, no fmt):
  ```bash
  cd deploy/terraform/run/<module>   # or deploy/terraform/bootstrap/<module>
  terraform init -backend=false
  terraform validate
  ```
- Every root module (`run/{sap_deployer,sap_landscape,sap_library,sap_system}`,
  `bootstrap/{sap_deployer,sap_library}`) has a `tests/` directory with
  `plan_shape.tftest.hcl` and `validation.tftest.hcl`, using `mock_provider`.
  Add/update these test cases alongside any Terraform change to a root module.
  Run tests with:
  ```bash
  cd deploy/terraform/run/<module>   # or deploy/terraform/bootstrap/<module>
  terraform init -backend=false
  terraform test
  ```
  Note: `terraform test`'s `mock_provider` cannot mock `ephemeral` resources,
  so CI temporarily rewrites `ephemeral "azurerm_key_vault_secret"` to
  `data "azurerm_key_vault_secret"` on the checked-out runner copy only
  (never committed) before running tests in modules that read secrets via an
  ephemeral key vault secret. Production code always uses `ephemeral` —
  don't "fix" this by changing production code to `data`.
- Lint with **tflint** (`.tflint.hcl` — `terraform` + `azurerm` ruleset
  plugins):
  ```bash
  tflint --chdir=deploy/terraform --recursive --minimum-failure-severity=error
  ```
- CI also runs a **checkov** static scan and a **terraform-docs** drift check.
  Reusable modules under `terraform-units/modules/` have generated
  `README.md` files — never hand-edit them; regenerate with:
  ```bash
  terraform-docs -c deploy/terraform/terraform-units/modules/.terraform-docs.yml markdown <module>
  ```

## Ansible conventions (`deploy/ansible/`)

- Playbooks are numbered sequentially (`playbook_00_validate_parameters.yaml`
  … `playbook_08_...yaml`) reflecting deployment phase order — preserve this
  numbering when adding new playbooks/tasks.
- Roles are split by concern into `roles-os/` (OS 1.x), `roles-sap-os/` (SAP
  OS 2.x), `roles-db/` (DB 4.x: HANA/Oracle/DB2/ASE), `roles-sap/` (SAP app
  5.x), `roles-misc/` (utilities 0.x), each using `X.Y-description` naming.
- Lint before proposing changes (mirrors CI):
  ```bash
  pip install ansible-core==2.16.* ansible-lint==24.9.2 jmespath netaddr
  ansible-galaxy collection install ansible.windows ansible.posix ansible.utils \
      ansible.netcommon:5.1.2 community.windows community.general:11.4.1 microsoft.ad --force
  ansible-lint deploy/ansible -c .ansible-lint
  ```
- `.ansible-lint` intentionally skips some rules — don't "fix" those without
  checking the skip list first.
- Preserve the existing SUSE Pacemaker self-key authorization pattern; it's a
  required part of the SLES 16 implementation — don't remove it.
- There are no Molecule tests. Python-level tests for Ansible filter/lookup
  plugins live under the top-level `tests/` tree — see Python testing below.

## Python testing (`tests/`)

All Python code in the repo — Ansible `filter_plugins`/`lookup_plugins` and
the `deploy/scripts/py_scripts/` CLIs — is tested with **pytest**, with test
files collected in a top-level `tests/` directory that **mirrors the source
tree** (tests are not colocated with the source they test).

When adding or modifying a Python file anywhere in `deploy/`, add or update
its corresponding test under `tests/deploy/<same relative path>/test_<name>.py`
rather than colocating the test next to the source.

- **Formatting**: all Python files (source and tests) must be formatted with
  **black** before committing:
  ```bash
  black deploy/ tests/
  ```
- **Coverage**: a minimum of **85% code coverage** is required. Run tests with
  coverage and verify the threshold before proposing changes:
  ```bash
  pytest tests/ -v --cov=deploy --cov-report=term-missing --cov-fail-under=85
  ```

## Web application (`Webapp/`)

- ASP.NET Core (.NET 9.0) MVC app backed by Azure Table Storage; see
  `Webapp/.github/copilot-instructions.md` for Azure-tool-usage rules that
  apply here (use Azure MCP tools, invoke `azmcp_bestpractices_get` first).
- Build: `dotnet build Webapp/SDAF/SDAFWebApp.csproj`.

## General formatting

- Line endings: LF for `.sh/.tf/.tfvars/.yml/.yaml`, CRLF for `.ps1` (enforced
  via `.gitattributes`) — don't normalize across these.
- Indentation per `.editorconfig`: 2 spaces default, 4 spaces for Python/C#,
  tabs for shell scripts.
- Trailing whitespace is trimmed everywhere except `.md`/`.diff`.

## Project structure

- `deploy/terraform/run/` : root Terraform modules (entry points), one per
  deployment stage (`sap_deployer`, `sap_library`, `sap_landscape`,
  `sap_system`).
- `deploy/terraform/bootstrap/` : first-time/local-backend variants of
  `sap_deployer` and `sap_library` used before remote state exists.
- `deploy/terraform/terraform-units/modules/` : reusable child modules
  referenced by the root modules; each has generated `README.md` files (via
  terraform-docs) — don't hand-edit these.
- `deploy/ansible/` : numbered playbooks (`playbook_00_...` – `playbook_08_...`)
  plus `roles-os/`, `roles-sap-os/`, `roles-db/`, `roles-sap/`, `roles-misc/`.
- `deploy/scripts/` : Bash/PowerShell/Python orchestration scripts invoked by
  pipelines or run manually (see Resources below).
- `deploy/pipelines/` : Azure DevOps pipeline YAML for the full deployment
  lifecycle (control plane → workload zone → SAP system → install → removal).
- `Webapp/` : ASP.NET Core configuration UI (has its own copilot instructions).
- `docs/` : architecture and reference documentation, including
  `repository_overview.md`.

## Resources

- `deploy/scripts/deploy_controlplane.sh` / `deploy_control_plane_v2.sh` :
  end-to-end control plane (deployer + library) deployment.
- `deploy/scripts/install_deployer.sh`, `install_library.sh`,
  `install_workloadzone.sh`, `installer.sh` : stage-by-stage deployment entry
  points; `remove_controlplane.sh` / `remove_control_plane_v2.sh` for teardown.
- `deploy/scripts/py_scripts/SDAF-GitHub-Actions/` : Python CLI for scaffolding
  GitHub Actions-based deployments.
- `.github/workflows/` : CI — `terraform-checks.yml` (validate/tflint/test/
  checkov/terraform-docs), `github-actions-ansible-lint.yml`, `codeql.yml`,
  `trivy.yml`.
- `docs/repository_overview.md` : full architecture, module map, and data
  flow — consult this before making cross-cutting changes.
