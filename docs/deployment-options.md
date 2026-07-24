# Choose an SDAF deployment option

SAP Deployment Automation Framework (SDAF) supports GitHub Actions, Azure
DevOps, and local scripted execution. The models use the same Terraform,
Ansible, and deployment lifecycle. They differ in how you configure the
environment, run automation, manage identity, and approve changes.

Samples and bill of materials (BOM) files are shared inputs. They are not a
separate execution model.

## Select an execution model

1. Identify the system that will own your deployment configuration.
2. Confirm whether the deployment must run in GitHub Actions, Azure Pipelines,
   or on an operator-managed host.
3. Compare the configuration generation, identity, runner or agent, approval,
   and update capabilities in the following table.
4. Open the start page for the selected model.
5. Review the model-specific prerequisites before you create Azure resources.

After these steps, you have selected the repository and automation boundary
for your SDAF deployment.

| Consideration | GitHub Actions | Azure DevOps | Local or scripted execution |
| --- | --- | --- | --- |
| Configuration repository | GitHub repository created from the GitHub bootstrap template | Azure Repos customer repository created or configured for SDAF | Operator-managed working directory or source-control repository |
| Automation host | GitHub Actions workflows | Azure Pipelines | Workstation, deployer, or another operator-managed automation host |
| Runner or agent | GitHub-hosted execution for generation; deployment runner behavior is workflow-specific | Microsoft-hosted or self-hosted agent pools, including deployer agents | Host prepared and maintained by the operator |
| Azure identity | GitHub environments, repository secrets and variables, and the workflow Azure sign-in | Azure service connections, variable groups, and bootstrap credentials | Azure CLI or explicitly configured service-principal or managed-identity credentials |
| Configuration generation | Workflows generate control-plane, workload-zone, and SAP-system `WORKSPACES` files | The sample pipeline generates control-plane examples; project utilities configure Azure DevOps resources and variables | No hosted stage generator; prepare files from samples, the Web application where applicable, or direct editing |
| Approval boundary | Workflow dispatch, repository permissions, and GitHub environment controls | Pipeline stages and Azure DevOps checks or approvals where configured | Explicit operator review before each state-changing command |
| Terraform state | Shared SDAF state accessed through the workflow identity | Shared SDAF state accessed through the pipeline identity | Shared SDAF state accessed from the execution host |
| Platform update flow | Update the configuration repository and workflow template through GitHub review | Use repository and pipeline update wrappers where applicable | The operator controls source version updates and script execution |
| Recovery and removal | GitHub removal workflows | Terraform removal, ARM fallback, and control-plane removal wrappers; no dedicated recovery wrapper was identified | Core state, recovery, and removal scripts |

The table describes capability differences, not a ranking. Select the model
that meets your organization's source-control, identity, governance, and
operations requirements.

## GitHub Actions

Choose GitHub Actions when GitHub owns the configuration repository and
workflow approvals.

The
[`Azure/sap-automation-gh-bootstrap`](https://github.com/Azure/sap-automation-gh-bootstrap)
repository provides:

- GitHub repository bootstrap and environment setup.
- Workflows that generate control-plane, workload-zone, and SAP-system
  configuration.
- Workflows that deploy each infrastructure stage.
- Workflows for software download, installation, and removal.

> [!WARNING]
> Do not dispatch workflow `07 - Operating System Configuration and
> Installation` until its invalid YAML indentation and inconsistent inventory
> path handling are corrected and validated. The owning repository documents
> these current implementation limitations.

Start the GitHub Actions setup:

1. Review the
   [repository prerequisites](https://github.com/Azure/sap-automation-gh-bootstrap#use-sap-deployment-automation-framework-from-github).
2. Select **Use this template** to
   [create the configuration repository](https://github.com/new?template_name=sap-automation-gh-bootstrap&template_owner=Azure).
3. In the configuration repository, run
   [`00 - Create environment`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/main/.github/workflows/00-create-environment.yml)
   to create the control-plane environment and configuration.
4. Review and approve the generated environment variables, secrets, and
   `WORKSPACES` configuration.
5. Run
   [`01 - Deploy Control Plane`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/main/.github/workflows/01-deploy-control-plane.yml)
   only after the required configuration and approvals are available.

After these steps, the control-plane inputs are ready for the first deployment
workflow.

## Azure DevOps

Choose Azure DevOps when Azure Repos, Azure Pipelines, service connections,
variable groups, and agent pools own the deployment process.

The
[`Azure/sap-automation-bootstrap`](https://github.com/Azure/sap-automation-bootstrap)
repository provides wrapper pipelines for control-plane, workload-zone,
SAP-system, software-download, installation, update, and removal
operations.

Azure DevOps does not currently provide verified one-to-one equivalents for
all GitHub stage-specific configuration-generation workflows. Pipeline
`22-sample-deployer-configuration.yml` generates deployer and library
examples. The `New-SDAFADOProject` and `New-SDAFADOWorkloadZone` utilities
configure project resources and variable groups. Prepare and review
workload-zone and SAP-system configuration explicitly before you run their
deployment pipelines.

Start the Azure DevOps setup:

1. Review the
   [`Azure/sap-automation-bootstrap`](https://github.com/Azure/sap-automation-bootstrap)
   repository layout and pipeline ownership.
2. Review the
   [`New-SDAFADOProject`](../deploy/scripts/pwsh/SDAFUtilities/Public/New-SDAFADOProject.ps1)
   utility before you create or configure the Azure DevOps project.
3. Review the
   [`New-SDAFADOWorkloadZone`](../deploy/scripts/pwsh/SDAFUtilities/Public/New-SDAFADOWorkloadZone.ps1)
   utility before you configure workload-zone resources and variables.
4. Prepare and approve the required `WORKSPACES` configuration.
5. Select the corresponding wrapper in the
   [`pipelines`](https://github.com/Azure/sap-automation-bootstrap/tree/main/pipelines)
   directory only after its inputs are available.

After these steps, the Azure DevOps project resources and deployment inputs
are ready for the first applicable wrapper pipeline.

## Local or scripted execution

Choose local execution when you need to run SDAF directly from a workstation,
deployer, or another automation host without a GitHub Actions or Azure
Pipelines wrapper.

Local infrastructure deployment uses the entry points under
[`deploy/scripts`](../deploy/scripts/). Local software download and
installation use the [`download_menu.sh`](../deploy/ansible/download_menu.sh)
and
[`configuration_menu.sh`](../deploy/ansible/configuration_menu.sh)
Ansible wrappers. These entry points consume the same configuration and state
model used by the hosted execution models.

Local execution does not provide a hosted stage-specific configuration
generator. Prepare configuration from the
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples)
repository, the SDAF Web application where applicable, or direct editing.
Validate every file before you run a deployment script.

The repository contains both established and v2 script families. Do not infer
support status from a filename. Use only an entry point that your release
guidance identifies and validate it against the checked-out repository
version.

## Shared samples and BOM files

All execution models can use
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples):

- `Terraform/WORKSPACES` for Terraform configuration examples.
- `SAP` for SAP application definitions.
- `BOM` for SAP software BOM files.
- `Ansible` for Ansible sample inputs.

Copy or reference the required sample from your configuration repository or
working directory. Review every sample before use because names, regions,
networking, sizing, and credentials are environment-specific.

## Continue

After you select an execution model:

1. Review [SDAF repositories](repositories.md) to understand ownership and
   dependencies.
2. Open the repository that owns the selected automation.
3. Complete planning and prerequisites before you bootstrap the environment.
