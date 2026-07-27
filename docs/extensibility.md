# Extend SAP Deployment Automation Framework

SAP Deployment Automation Framework (SDAF) provides configuration inputs and
Ansible hooks for organization-specific requirements. Use the least invasive
extension that meets the requirement so that framework updates remain
reviewable.

## Choose an extension approach

Use the following order:

1. Set an existing Terraform or `sap-parameters.yaml` input.
2. Use a supported configuration collection such as custom packages or mounts.
3. Add an organization-owned Ansible pre- or post-playbook.
4. Add an organization-owned stage to the execution wrapper.
5. Fork the framework only when the earlier options can't implement the
   requirement.

| Approach | Organization owns | Framework integration | Update responsibility |
| --- | --- | --- | --- |
| Existing parameter | Parameter value and validation | Terraform variable or Ansible variable | Revalidate the value when its contract changes |
| Configuration collection | Entries in generated or reviewed `sap-parameters.yaml` | Existing SDAF Ansible role | Validate schema and target-node selection |
| Ansible hook | Playbook, dependencies, idempotence, and recovery | Pre- or post-hook around a numbered SDAF playbook | Test against every adopted SDAF release |
| Wrapper stage | Workflow or pipeline stage and its identity | Organization-selected placement before or after core automation | Maintain the wrapper and approval flow |
| Source fork | All changed source and integration behavior | Organization-maintained branch of SDAF | Merge, test, and support upstream updates |

> [!NOTE]
> Code that can be modified isn't automatically a supported extension point.
> This article identifies inputs and hooks that the current implementation
> reads explicitly.

## Extend generated Ansible configuration

The SAP-system Terraform root passes
[`configuration_settings`](../deploy/terraform/run/sap_system/tfvar_variables.tf)
to the
[`output_files`](../deploy/terraform/terraform-units/modules/sap_system/output_files/)
module. The module includes those settings in generated Ansible parameters.
You can review the resulting values in `sap-parameters.yaml`, but don't
maintain extensions by editing that generated file directly. A later
Terraform apply regenerates the file and can overwrite manual changes. Store
durable extension values in `configuration_settings` in the SAP-system
configuration.

The following extension collections are implemented by current Ansible roles:

| Input | Purpose | Implementing source |
| --- | --- | --- |
| `custom_repos` | Register additional Linux package repositories by distribution | [`roles-os/1.3-repository`](../deploy/ansible/roles-os/1.3-repository/) |
| `custom_packages` | Install or remove additional Linux packages by distribution and node tier | [`roles-os/1.4-packages`](../deploy/ansible/roles-os/1.4-packages/) |
| `custom_logical_volumes` | Create additional volume groups, logical volumes, file systems, and mount points | [`roles-os/1.5-disk-setup`](../deploy/ansible/roles-os/1.5-disk-setup/) |
| `custom_parameters` | Manage additional Linux kernel parameters | [`roles-os/1.9-kernelparameters`](../deploy/ansible/roles-os/1.9-kernelparameters/) |
| `custom_services` | Manage additional Linux services by distribution and node tier | [`roles-os/1.16-services`](../deploy/ansible/roles-os/1.16-services/) |
| `custom_exports` | Export additional directories from the applicable SAP central-services host | [`roles-sap-os/2.3-sap-exports`](../deploy/ansible/roles-sap-os/2.3-sap-exports/) |
| `custom_mounts` | Mount additional NFS paths on selected SAP node tiers | [`roles-sap-os/2.6-sap-mounts`](../deploy/ansible/roles-sap-os/2.6-sap-mounts/) |

Other configuration settings support organization-selected user and group IDs,
virtual host names, volume sizes, and disk stripe sizes. Use only keys consumed
by the checked-out release. Unknown values can be written to generated
configuration without proving that a playbook uses them.

Before you add a configuration extension:

1. Confirm the target role runs for the selected operating system and node
   tier.
2. Confirm the expected data shape in the implementing role.
3. Review package, repository, file-system, and service changes with the
   operating-system owner.
4. Test idempotence and removal behavior.
5. Retain the reviewed configuration in source control without credentials.

Use the implementing roles in the preceding table as the contract for current
key names, data shapes, defaults, and platform conditions.

## Use custom sizing

SDAF provides sizing dictionaries and explicit overrides for SAP-system
compute and storage. Select sizing from SAP workload requirements; don't treat
the framework defaults as a substitute for SAP sizing.

The SAP-system root supports:

- Database sizing keys such as `database_size` and
  `db_sizing_dictionary_key`.
- An explicit database VM SKU through `database_vm_sku`.
- Application-tier sizing keys such as `application_size` and
  `app_tier_sizing_dictionary_key`.
- A shared custom disk configuration through `custom_disk_sizes_filename`.
- Tier-specific disk files through `db_disk_sizes_filename` and
  `app_disk_sizes_filename`.

A custom disk configuration is a JSON file with `db`, `app`, `scs`, and `web`
sections. Each sizing entry can define the default VM size and storage layout
for that tier. Store the file beside the SAP-system parameter file and use a
path relative to the directory that contains the `tfvars` file.

Before you use custom sizing:

1. Size the SAP workload and identify certified VM and storage options.
2. Verify regional SKU availability, quota, disk limits, throughput, and IOPS.
3. Define the smallest custom sizing entry that meets the requirement.
4. Confirm LUN numbers, caching, write acceleration, striping, and mount
   behavior.
5. Review the Terraform plan for replacements and disk changes.
6. Test provisioning and Ansible disk configuration in a representative
   nonproduction system.

Use the built-in
[`deploy/configs`](../deploy/configs/) sizing dictionaries as schema examples
and review the current
[`sap_system` sizing inputs](../deploy/terraform/run/sap_system/tfvar_variables.tf).
Don't edit the built-in dictionaries to create custom sizing. Keep the custom
JSON file with the SAP-system parameters.

## Use custom naming

SDAF generates names through the
[`sap_namegenerator`](../deploy/terraform/terraform-units/modules/sap_namegenerator/)
module. Use parameter overrides before changing that module.

The root modules accept `name_override_file`, which points to a JSON file
containing resource-name overrides. The SAP-system root merges supplied
top-level and virtual-machine names with generated defaults, so omitted entries
continue to use framework naming.

You can also use focused parameters such as:

- `custom_prefix` and `use_prefix` for the deployment prefix.
- `resourcegroup_name` for a resource-group override.
- Documented subnet and network-security-group name parameters.
- `custom_scs_virtual_hostname`, `custom_ers_virtual_hostname`,
  `custom_db_virtual_hostname`, and `custom_pas_virtual_hostname` for
  applicable SAP host-name behavior in generated Ansible configuration.

Azure resource-name overrides and SAP virtual-host-name overrides are separate
contracts. Don't assume that changing one renames the other.

Before you use custom naming:

1. Inventory every resource type that requires an override.
2. Preserve JSON keys consumed by the current naming contract.
3. Validate Azure character, length, uniqueness, and global-name requirements.
4. Keep related names consistent across the control plane, workload zone, and
   SAP system.
5. Review the Terraform plan for resource replacement before deployment.
6. Retain the override file with the deployment configuration and test it against
   each adopted SDAF release.

Use the current root-module `name_override_file` variables, the
[`sap_namegenerator`](../deploy/terraform/terraform-units/modules/sap_namegenerator/)
output contract, and the
[`custom_names.json`](../deploy/terraform/run/sap_library/tests/fixtures/custom_names.json)
test fixture as the repository-owned references. Modifying or replacing
`sap_namegenerator` is a source customization and requires the fork maintenance
controls described later in this article.

## Run custom Ansible playbooks

SDAF can run a custom playbook immediately before or after a numbered
framework playbook. The directory name is execution-path specific: local
execution reads `ANSIBLE`, while the hosted helper reads `Ansible`. Preserve
the documented casing on Linux.

Name each hook after the framework playbook it extends:

| Execution path | Framework playbook | Pre-hook | Post-hook |
| --- | --- | --- | --- |
| Local `configuration_menu.sh` | `playbook_01_os_base_config.yaml` | `playbook_01_os_base_config_pre.yaml` | `playbook_01_os_base_config_post.yaml` |
| Hosted pipeline helper | `playbook_01_os_base_config.yaml` | `playbook_01_os_base_config_pre.yml` | `playbook_01_os_base_config_post.yml` |

The extension difference is significant:

- [`configuration_menu.sh`](../deploy/ansible/configuration_menu.sh) derives
  `.yaml` hook names and reads them from
  `$CONFIG_REPO_PATH/ANSIBLE`.
- The hosted
  [`05-run-ansible.sh`](../deploy/scripts/pipeline_scripts/v2/05-run-ansible.sh)
  helper derives `.yml` hook names and reads them from `./Ansible` in the
  checked-out configuration repository.
- The hosted helper also loads `extra-params.yaml` from the current SAP-system
  parameter directory when the file exists.

Neither wrapper treats a failed pre-hook as a safety gate. Both continue to
the framework playbook after reporting the pre-hook result. The local wrapper
stops its playbook loop when a framework playbook fails, but hook failures
don't stop the loop. In the hosted helper, a later framework or post-hook run
can overwrite an earlier nonzero return code; the helper exits with the most
recently recorded playbook result. If an extension must block later work,
enforce and preserve its exit status in the owning wrapper stage.

Review the owning GitHub workflow or Azure DevOps pipeline before relying on a
hook. A wrapper must invoke the relevant helper and check out the
configuration repository in the expected location.


## Add wrapper stages

GitHub Actions and Azure DevOps can run organization-owned checks or operations
before or after an SDAF stage. Keep these stages in the configuration
repository and call stable core entry points rather than copying core scripts.

For each custom stage:

1. Define its identity and least-privilege permissions.
2. Define whether it reads or changes Terraform state, Azure resources, or
   managed hosts.
3. Place approval and maintenance-window checks before state-changing actions.
4. Preserve core stage ordering and remote-state dependencies.
5. Publish logs and validation evidence with the deployment record.
6. Test the stage whenever the adopted SDAF release changes.

Pipeline customization is owned by the execution repository. See
[SDAF repositories](repositories.md) before selecting the change location.

## Extend SAP software definitions and BOMs

SAP application definitions and BOM files are deployment inputs.
Start from
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples),
then retain reviewed organization-specific changes in the configuration
repository.

Validate product IDs, archive names, checksums, download permissions,
installation templates, and dependencies. A custom BOM changes the software
acquisition and installation input; it doesn't change the Terraform
infrastructure support matrix.

## Maintain a source fork

A fork gives full control over Terraform modules, Ansible roles, scripts, and
pipeline templates, but it also transfers maintenance responsibility.

Before adopting a fork:

1. Record why built-in inputs and hooks are insufficient.
2. Minimize the changed surface and avoid copying generated files.
3. Add tests for every modified Terraform module, Ansible role, or script.
4. Define how upstream security and release changes are merged.
5. Revalidate supported operating systems, databases, and storage after each
   merge.
6. Document which behavior is Microsoft-provided and which behavior is
   organization-maintained.

Microsoft supportability statements for the upstream framework don't establish
support for organization-specific modifications.


Review [SDAF supportability](supportability.md) before an extension changes an
operating system, database, storage, or topology assumption.
