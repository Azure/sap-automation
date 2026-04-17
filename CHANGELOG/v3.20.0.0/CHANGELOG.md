# Release Notes: SDAF 3.20.0.0

## Functional Differences

### 1. BoM and Installation Flow Enhancements
- BoM processing, validation, and registration logic was refactored and expanded:
- Menu/script handling for BoM updated:
- Added support paths for HANA-only deployments and JAVA product handling in playbooks.

### 2. Oracle/DB and SAP Playbook Refactoring
- Oracle ASM and Data Guard roles were refactored for consistency and reliability:
- New cleanup task introduced:
- Multiple SAP install roles updated (SCS, PAS, APP, DBLOAD, Web):

### 3. OS Configuration, SAP Installation and Package Management
- Add JAVA installation support for SCS, PAS, and Application Servers
- Support for HANA only deployments
- Red Hat package update conditions corrected to include `upgrade_packages` path.
- DB2 tier support improved with `systemd-libs` packaging updates.
- SUSE subscription and repository handling fixes across repository/package tasks.
- `/etc/hosts` handling improved using a custom Ansible filter plugin:
	- `deploy/ansible/roles-sap-os/2.4-hosts-file/filter_plugins/sap_hosts_filters.py`

### 4. Terraform and Infrastructure Changes
- Terraform version references updated from 1.14.6 to 1.14.8 in `tfvar_variables.tf` files.
- Terraform init command cleanup in scripts (removed redundant `true` flags).
- AFS/storage and inventory generation behavior improved in Terraform modules.
- Network Security Perimeter support added

### 5. Pipeline, Tooling, and Dependency Updates
- Authentication and deployment pipeline scripts were updated across v1 and v2 flow scripts.
- .NET and action dependencies bumped (for example `Azure.Identity`, `dotnet-ef`, container/action workflow pins).
- Python dependency updates include requests pinning update to `2.32.5`.

## Notes
