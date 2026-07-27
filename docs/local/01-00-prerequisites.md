# Review prerequisites for local execution

## Outcome

You have an approved architecture, execution host, identity, network design,
quota, and configuration source before you install tools or create Azure
resources.

## Supported execution host

The local entry points are Bash scripts that call Linux command-line tools.
They are designed to run in any environment that provides Bash and the
required command-line dependencies. An operator-managed Linux host, including
an SDAF deployer after it exists, provides the documented setup path. The
repository's
[`configure_deployer.sh`](../../deploy/scripts/configure_deployer.sh) setup
path accepts Ubuntu, RHEL, SLES 15.0 through 15.3, and SLES 15.8 or later.
This setup path requires an x86_64 or amd64 host because it downloads the
Terraform `linux_amd64` archive.

On another Bash environment or on ARM64, install and validate the required
tools through a separately reviewed process instead of
`configure_deployer.sh`.

## Before you begin

Confirm the following requirements:

- An Azure subscription for the control plane and each workload subscription.
- Permission to create the resource types selected in the `.tfvars` files.
- Permission to create role assignments when the configuration requires SDAF
  to assign Contributor, User Access Administrator, Key Vault, Storage, DNS,
  or other roles.
- For the established control-plane path without MSI-only deployment, an
  approved service-principal application ID, tenant ID, client secret, and
  subscription ID. Provide them through the approved secure input method or
  the `ARM_CLIENT_ID`, `ARM_TENANT_ID`, and `ARM_CLIENT_SECRET` environment
  variables when the scripts require them. An interactive Azure user sign-in
  does not replace these inputs for `set_secrets.sh`.
- An approved management virtual network and subnet, or approved address
  spaces for SDAF to create them.
- Name resolution and routing between the execution host, Azure Resource
  Manager, Microsoft Entra ID, Azure Storage, Key Vault, and any private
  endpoints.
- Outbound access to provider and package sources used by Terraform, Azure
  CLI, Ansible, operating-system repositories, and SAP software sources.
- Azure compute quota for every selected VM family and region.
- SAP software licenses and an SAP Support user when the selected download
  method requires them.
- A source-control and backup policy for configuration and operational
  evidence.

## Pin versions

Treat the SDAF commit and tool versions as one reviewed release unit.

1. Identify the approved SDAF commit from your release guidance and record it
   as `<SDAF_COMMIT>`.

   Verify this value with `git rev-parse HEAD` after checking out the repository
   on the next page.

2. Review each Terraform root module's `providers.tf` before installation.

   This baseline declares Terraform `>= 1.0` and pins root providers including
   AzureRM `4.80.0`, AzAPI `2.7.0`, and AzureAD `3.8.0` where applicable. The
   root modules declare the Random provider without a version constraint.

3. If you use `configure_deployer.sh`, review its pinned defaults.

   At this baseline it defaults to Terraform `1.14.6`. It selects Ansible 2.16
   for Ubuntu 22.04, RHEL, and SLES 16, and Ansible 2.11 for other accepted
   SLES versions.

4. Record the installed versions after host preparation.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/helpers/check_workstation.sh"
   ```

   The command prints the detected Azure CLI, Terraform, Ansible, and `jq`
   versions.

> [!IMPORTANT]
> Do not update the SDAF checkout, Terraform, providers, or Ansible between a
> plan and its apply. Replan after any version change.

## Plan identity and access

Choose one identity model for each execution host:

- **Azure CLI user sign-in**: Run `az login`, select the target subscription,
  and use the signed-in user.
- **Service principal**: Export the `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`,
  `ARM_TENANT_ID`, and `ARM_SUBSCRIPTION_ID` variables. Protect the secret from
  shell history, process listings, logs, and source control.
- **Managed identity**: Use an Azure host with an assigned identity and the
  script family's managed-identity option only when your release guidance
  selects that path.

The deployment identity must be able to read existing networks, DNS zones,
Key Vaults, and the remote-state storage account that the configuration
references. It must also be able to create the role assignments represented
by the selected Terraform configuration.

## Review networking, DNS, and quota

1. Validate every virtual network and subnet CIDR against the enterprise IP
   allocation.
2. Validate peering, routes, firewalls, and network security controls.
3. Decide whether public endpoints or private endpoints provide access to
   Storage, Key Vault, and other services.
4. Validate the management and private-link DNS subscription and resource
   group values when DNS is managed outside the deployment subscription.
5. Confirm that the execution host's public IP can be authorized temporarily
   when a selected script updates Key Vault or Storage network rules.
6. Confirm regional VM-family and total vCPU quota for the complete SAP
   system, including high-availability nodes.

## Review configuration ownership

Use
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples)
as the owner of:

- `Terraform/WORKSPACES` examples.
- `SAP` application definitions.
- `BOM` software bills of materials.
- `Ansible` sample inputs.

Copy only the required examples into the customer configuration repository.
Review names, subscriptions, regions, networks, sizes, images, availability,
credentials, and feature flags. Samples are not production approval.

## Review gate

Do not continue until architecture, security, networking, DNS, quota, cost,
identity, configuration ownership, version pins, backup, and removal
responsibilities have named approvers.

## Next step

[Prepare the local execution environment](02-00-prepare-execution-environment.md).
