# Prepare the local execution environment

## Outcome

The Linux execution host has reviewed and recorded tool versions, an
authenticated Azure identity, an SDAF checkout, a separate configuration
root, and reviewed stage inputs.

## Before you begin

Complete [local execution prerequisites](01-00-prerequisites.md). Run these
steps as a regular user with `sudo` permission. Do not run
`configure_deployer.sh` as `root` or with `sudo`.

## Inputs

Define these placeholders:

- `<SDAF_COMMIT>`: Approved `Azure/sap-automation` commit.
- `<CONFIG_ROOT>`: Absolute path to the customer configuration root.
- `<SUBSCRIPTION_ID>`: Initial target Azure subscription.
- `<ABSOLUTE_PATH_TO_SAP_AUTOMATION_SAMPLES>`: Absolute path to the reviewed
  `Azure/SAP-automation-samples` checkout.

The scripts require:

- `SAP_AUTOMATION_REPO_PATH`: SDAF checkout root.
- `CONFIG_REPO_PATH`: Customer configuration root.
- `ARM_SUBSCRIPTION_ID`: Current target subscription.

Later stages persist nonsecret environment metadata under
`$CONFIG_REPO_PATH/.sap_deployment_automation`.

## What the automation does

`configure_deployer.sh` prepares a Linux host with Terraform, Azure CLI,
Ansible, required Python packages, Ansible collections, and .NET 9. It upgrades
or patches distribution packages before installing the toolchain. Terraform is
version-pinned, but Azure CLI, the Ansible patch release, .NET channel updates,
several Python packages, and several collections can resolve newer versions.
On RHEL and SLES, the script also installs `virtualenv` into system Python
before creating the Python virtual environment under `/opt/ansible`. It writes
`/etc/profile.d/deploy_server.sh`.

The script does not create customer `WORKSPACES` configuration or approve an
Azure deployment.

## Prepare the host

1. Clone the SDAF repository.

   ```bash
   mkdir -p "$HOME/Azure_SAP_Automated_Deployment"
   git clone https://github.com/Azure/sap-automation.git \
     "$HOME/Azure_SAP_Automated_Deployment/sap-automation"
   ```

   The repository is created at the fixed checkout path used by
   `configure_deployer.sh`.

2. Check out the approved commit.

   ```bash
   cd "$HOME/Azure_SAP_Automated_Deployment/sap-automation"
   git checkout <SDAF_COMMIT>
   git rev-parse HEAD
   ```

   Git reports a detached HEAD at the approved commit unless the commit is on
   a local release branch, and `rev-parse` returns the recorded commit.

3. Export the source and configuration paths.

   ```bash
   export SAP_AUTOMATION_REPO_PATH="$(pwd)"
   export CONFIG_REPO_PATH="<CONFIG_ROOT>"
   export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
   ```

   Each variable resolves to a nonempty absolute path or subscription ID.

4. Create the configuration root.

   ```bash
   mkdir -p "$CONFIG_REPO_PATH/WORKSPACES"
   ```

   The `WORKSPACES` directory exists outside the SDAF checkout.

5. Prepare the Linux toolchain.

   ```bash
   TF_VERSION=1.14.6 \
     "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/configure_deployer.sh"
   ```

   The script upgrades or patches operating-system packages, installs
   Terraform under `/opt/terraform`, Azure CLI, .NET 9, Ansible dependencies,
   and a profile script under `/etc/profile.d`. On RHEL and SLES, it installs
   `virtualenv` into system Python before creating the environment under
   `/opt/ansible`.

   > [!WARNING]
   > Run this step only in an approved maintenance window. Distribution package
   > updates can affect software unrelated to SDAF and can require a host
   > restart.

   If your organization manages these tools separately, install the approved
   versions through that process instead. The deployment scripts check that
   Terraform and Azure CLI are available.

6. Start a new shell or load the generated profile when present.

   ```bash
   if [ -f /etc/profile.d/deploy_server.sh ]; then
     source /etc/profile.d/deploy_server.sh
   fi
   export SAP_AUTOMATION_REPO_PATH="$HOME/Azure_SAP_Automated_Deployment/sap-automation"
   export CONFIG_REPO_PATH="<CONFIG_ROOT>"
   export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
   ```

   Terraform, Azure CLI, Ansible, and SDAF scripts are available on `PATH`.
   Re-exporting the reviewed values is required because the generated profile
   sets its current subscription and fixed default repository paths.

   The generated profile also sets `ANSIBLE_HOST_KEY_CHECKING=False`. Before
   running configuration, verify each target host key through an approved
   out-of-band source. If your security policy requires strict checking,
   populate the approved `known_hosts` file and export
   `ANSIBLE_HOST_KEY_CHECKING=True` after loading the profile.

7. Verify the tool versions.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/helpers/check_workstation.sh"
   ```

   The command prints a version for `az`, `terraform`, `ansible`, and `jq`.

8. Sign in to Azure.

   ```bash
   az login
   az account set --subscription "$ARM_SUBSCRIPTION_ID"
   az account show --query '{subscription:id,tenant:tenantId,user:user.name}' \
     --output table
   ```

   The output identifies the intended subscription, tenant, and principal.
   Use the approved service-principal or managed-identity sign-in instead when
   that identity model applies.

## Prepare configuration

Local execution has no hosted stage-specific generator.

1. Clone or browse
   [`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples).
2. Copy the required `Terraform/WORKSPACES` examples into
   `$CONFIG_REPO_PATH/WORKSPACES`.
3. Use the SDAF Web application where applicable to create, upload, edit, and
   download workload-zone or SAP-system `.tfvars` files.
4. Review direct edits in source control before execution.
5. Preserve the directory and file naming relationship expected by the
   scripts: each stage directory contains its same-named `.tfvars` file.

The Web application assists with configuration. It does not replace local
identity setup, plan review, or script execution.

## Protect secrets and transient files

- Store deployment credentials in the configured Azure Key Vault.
- Keep `ARM_CLIENT_SECRET`, SAP credentials, private keys, and downloaded
  software out of Git.
- Exclude `.terraform/`, `.sap_deployment_automation/`, `terraform.tfstate`,
  `*.tfplan`, `apply_output.*`, `plan_output.log`, `sshkey`, and generated
  secret-bearing files from source control.
- Restrict permissions on the execution host and configuration root.
- Do not enable `DEBUG` when environment variables can contain secrets.

## Review gate

Review the exact commit, tool versions, Azure principal, subscription,
configuration diff, ignored files, and outbound connectivity. Do not run a
deployment command until the review is recorded.

## Validate

Confirm that:

- The SDAF checkout is at the approved commit.
- `SAP_AUTOMATION_REPO_PATH`, `CONFIG_REPO_PATH`, and
  `ARM_SUBSCRIPTION_ID` have the expected values.
- Azure CLI, Terraform, Ansible, and `jq` report the approved versions.
- `az account show` reports the approved principal, tenant, and subscription.
- The configuration root contains reviewed stage directories and no secrets
  are tracked by source control.

## Safe retry

Do not treat a host-setup rerun as deterministic. It repeats the
operating-system upgrade or patch and can resolve newer unpinned Azure CLI,
Ansible patch, Python package, .NET channel, and collection versions. Obtain a
new maintenance and version review, record the currently resolved versions,
and preserve approved profile customization elsewhere before rerunning
`configure_deployer.sh`.

## Next step

[Deploy the control plane](03-00-control-plane.md).
