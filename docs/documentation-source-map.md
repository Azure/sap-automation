# SDAF documentation source map

This source map records the implementation assets used to validate central
SAP Deployment Automation Framework (SDAF) documentation. Use it to prevent
capability statements from drifting away from current workflows, pipelines,
scripts, and samples.

This page is a maintainer reference. It does not replace the user procedures
in the owning repositories.

## Validation baseline

The source review was completed on 2026-07-24 against these repository
versions:

| Repository | Validated ref | Commit |
| --- | --- | --- |
| `Azure/sap-automation` | `release/july-2026` | `93785d789` |
| `Azure/sap-automation-gh-bootstrap` | `update-docs-templates` | `0ee1260a6` |
| `Azure/sap-automation-bootstrap` | `main` | `fd94e68d9` |
| `Azure/SAP-automation-samples` | `main` | `20a0b849b` |

Revalidate a row against the target branch before changing its capability
statement.

## Reference documentation sources

The architecture, extensibility, and supportability references use the
following baselines:

| Reference | Source | Validation use |
| --- | --- | --- |
| Framework architecture | [SAP Deployment Automation Framework](https://learn.microsoft.com/azure/sap/automation/deployment-framework) | Control plane, workload zone, SAP system, software acquisition, and SAP topology concepts |
| Extensibility | [Extend SAP Deployment Automation Framework](https://learn.microsoft.com/azure/sap/automation/extensibility) | Published configuration extensions and custom Ansible-hook patterns |
| Custom sizing | [Custom disk configuration reference](https://learn.microsoft.com/azure/sap/automation/configure-extra-disks) | Custom sizing JSON structure, file placement, and disk configuration behavior |
| Custom naming | [Configure custom naming](https://learn.microsoft.com/azure/sap/automation/naming-module) | Name-override JSON contract, naming inputs, and naming-module boundary |
| Technical supportability | [Supportability matrix for SAP Deployment Automation Framework](https://learn.microsoft.com/azure/sap/automation/supportability) | Published operating-system, database, storage, topology, and Azure capability matrices |
| Terraform architecture | [`deploy/terraform/run`](../deploy/terraform/run/) and [`deploy/terraform/bootstrap`](../deploy/terraform/bootstrap/) at `fe6a307d1c9d0dee81d1dfc486265276aed3b03a` | Root-module boundaries, remote-state dependencies, generated outputs, and bootstrap flow |
| Ansible extensions | [`deploy/ansible`](../deploy/ansible/) at `fe6a307d1c9d0dee81d1dfc486265276aed3b03a` | Custom repositories, packages, logical volumes, kernel parameters, services, exports, mounts, and local pre/post hooks |
| Hosted Ansible extensions | [`05-run-ansible.sh`](../deploy/scripts/pipeline_scripts/v2/05-run-ansible.sh) at `fe6a307d1c9d0dee81d1dfc486265276aed3b03a` | Hosted pre/post hook names, lookup path, extra parameters, and failure behavior |
| Azure region codes | [`variables_global.tf`](../deploy/terraform/terraform-units/modules/sap_namegenerator/variables_global.tf), [`variables_local.tf`](../deploy/terraform/terraform-units/modules/sap_namegenerator/variables_local.tf), [`resourcegroup.tf`](../deploy/terraform/terraform-units/modules/sap_namegenerator/resourcegroup.tf), [`deploy_utils.sh`](../deploy/scripts/deploy_utils.sh), [`helper.sh`](../deploy/scripts/pipeline_scripts/helper.sh), [`shared_functions.sh`](../deploy/scripts/pipeline_scripts/v2/shared_functions.sh), [`shared_functions_v2.sh`](../deploy/scripts/pipeline_scripts/v2/shared_functions_v2.sh), and [`22-sample-deployer-configuration.ps1`](../deploy/scripts/pipeline_scripts/22-sample-deployer-configuration.ps1) at `ae74249dc` | Region-to-code mapping, `location_short` derivation, `unkn` fallback, and the resource-name patterns that embed the code |
| Deployment validation | [`Azure/sap-automation-qa`](https://github.com/Azure/sap-automation-qa) at the version pinned by `sap_automation_qa_version` in [`ansible-input-api.yaml`](../deploy/ansible/vars/ansible-input-api.yaml) | Available playbooks, test groups, test cases, results layout, and report generation |

Supportability values in central documentation must remain distinguishable
from support policy. Implementation availability alone doesn't
establish support.

## Lifecycle capability sources

| Capability | Execution model | Source asset | Validation result |
| --- | --- | --- | --- |
| GitHub repository setup | GitHub Actions | [`SDAF-GitHub-Actions`](../deploy/scripts/py_scripts/SDAF-GitHub-Actions/) | Configures the GitHub App, repository variables and secrets, Azure identity, and required permissions. It dispatches workflow `00`, then configures the created environment and federated identity. |
| Control-plane configuration generation | GitHub Actions | [`00-create-environment.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/00-create-environment.yml) | Generates control-plane environment and `WORKSPACES` configuration from templates. |
| Workload-zone configuration generation | GitHub Actions | [`02-create-workload-environment.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/02-create-workload-environment.yml) | Generates workload-zone environment and configuration. |
| SAP-system configuration generation | GitHub Actions | [`04-create-system-environment.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/04-create-system-environment.yml) | Generates and commits SAP-system `WORKSPACES` configuration. It does not create a GitHub environment. |
| Control-plane sample generation | Azure DevOps | [`22-sample-deployer-configuration.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/22-sample-deployer-configuration.yml) | Generates deployer and library examples. It is not a complete equivalent of all GitHub generation workflows. |
| Azure DevOps project setup | Azure DevOps | [`New-SDAFADOProject.ps1`](../deploy/scripts/pwsh/SDAFUtilities/Public/New-SDAFADOProject.ps1) | Configures Azure DevOps project resources, pipelines, variables, and related deployment settings. |
| Azure DevOps workload-zone setup | Azure DevOps | [`New-SDAFADOWorkloadZone.ps1`](../deploy/scripts/pwsh/SDAFUtilities/Public/New-SDAFADOWorkloadZone.ps1) | Configures workload-zone Azure DevOps resources and variables. It does not generate a complete stage configuration equivalent to GitHub workflow `02`. |
| Local configuration preparation | Local | [`deploy/scripts`](../deploy/scripts/) and [`Terraform/WORKSPACES`](https://github.com/Azure/SAP-automation-samples/tree/20a0b849ba40ed816683ec1ce6a417f73276485d/Terraform/WORKSPACES) | No hosted stage generator exists. Users prepare configuration from samples, the Web application where applicable, or direct editing. |
| Control-plane deployment | GitHub Actions | [`01-deploy-control-plane.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/01-deploy-control-plane.yml) | Runs the GitHub control-plane deployment. |
| Control-plane deployment | Azure DevOps | [`01-deploy-control-plane.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/01-deploy-control-plane.yml) | Wraps the core control-plane pipeline template. |
| Control-plane deployment | Local | [`deploy_controlplane.sh`](../deploy/scripts/deploy_controlplane.sh) and [`deploy_control_plane_v2.sh`](../deploy/scripts/deploy_control_plane_v2.sh) | Local control-plane entry points exist. Release guidance must identify the supported entry point. |
| Workload-zone deployment | GitHub Actions | [`03-deploy-sap-workload-zone.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/03-deploy-sap-workload-zone.yml) | Deploys the workload zone from prepared configuration. |
| Workload-zone deployment | Azure DevOps | [`02-sap-workload-zone.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/02-sap-workload-zone.yml) | Wraps the core workload-zone pipeline template. |
| Workload-zone deployment | Local | [`install_workloadzone.sh`](../deploy/scripts/install_workloadzone.sh) | Consumes prepared landscape configuration. |
| SAP-system deployment | GitHub Actions | [`05-sap-system-deployment.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/05-sap-system-deployment.yml) | Deploys SAP-system infrastructure from prepared configuration. |
| SAP-system deployment | Azure DevOps | [`03-sap-system-deployment.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/03-sap-system-deployment.yml) | Wraps the core SAP-system pipeline template. |
| SAP-system deployment | Local | [`installer.sh`](../deploy/scripts/installer.sh) and [`installer_v2.sh`](../deploy/scripts/installer_v2.sh) | Local system entry points exist. Release guidance must identify the supported entry point. |
| SAP software download | GitHub Actions | [`06-sap-software-download.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/06-sap-software-download.yml) and [`065-sap-software-download.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/065-sap-software-download.yml) | Workflow `06` selects a predefined combined BOM. Workflow `06.5` selects separate application, database, and kernel BOMs and combines them under the selected name. |
| SAP software download | Azure DevOps | [`04-sap-software-download.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/04-sap-software-download.yml) and [`04-sap-software-download_v2.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/04-sap-software-download_v2.yml) | Wrapper variants exist. Detailed guidance must explain selection criteria after owner confirmation. |
| SAP software download | Local | [`download_menu.sh`](../deploy/ansible/download_menu.sh) and [`playbook_bom_downloader.yaml`](../deploy/ansible/playbook_bom_downloader.yaml) | Runs the local BOM-driven software download path. |
| SAP software definitions | Shared | [`SAP`](https://github.com/Azure/SAP-automation-samples/tree/20a0b849ba40ed816683ec1ce6a417f73276485d/SAP) and [`BOM`](https://github.com/Azure/SAP-automation-samples/tree/20a0b849ba40ed816683ec1ce6a417f73276485d/BOM) | The samples repository owns SAP definitions and BOM files for every execution model. |
| OS, database, and SAP installation | GitHub Actions | [`07-configuration-installation.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/07-configuration-installation.yml) | Currently blocked by invalid YAML indentation and inconsistent inventory path handling. Do not dispatch the workflow until both issues are corrected and validated. |
| OS, database, and SAP installation | Azure DevOps | [`05-DB-and-SAP-installation.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/05-DB-and-SAP-installation.yml) and [`07-sap-cal-installation.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/07-sap-cal-installation.yml) | Provides the standard installation wrapper and an Azure DevOps CAL path. |
| OS, database, and SAP installation | Local | [`configuration_menu.sh`](../deploy/ansible/configuration_menu.sh) and [`deploy/ansible`](../deploy/ansible/) | Uses the local Ansible wrapper and numbered playbooks. |
| Deployment validation | Azure DevOps | [`13-sap-automation-qa.yaml`](../deploy/pipelines/13-sap-automation-qa.yaml), [`13-sap-automation-qa.sh`](../deploy/scripts/pipeline_scripts/13-sap-automation-qa.sh), and [`roles-misc/0.10-sap-automation-qa`](../deploy/ansible/roles-misc/0.10-sap-automation-qa/) | Prepares the agent, then runs the selected [`Azure/sap-automation-qa`](https://github.com/Azure/sap-automation-qa) playbook and collects the report. Requires a self-hosted agent. |
| Deployment validation | Local | [`quality_assurance_menu.sh`](../deploy/ansible/quality_assurance_menu.sh) and [`playbook_06_03_00_sap_functional_tests.yaml`](../deploy/ansible/playbook_06_03_00_sap_functional_tests.yaml) | Runs the same preparation role and framework playbooks from an operator-managed host. |
| Deployment validation | GitHub Actions | No direct equivalent | No quality assurance workflow exists in [`Azure/sap-automation-gh-bootstrap`](https://github.com/Azure/sap-automation-gh-bootstrap). |
| Repository updates | Azure DevOps | [`20-update-repositories.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/20-update-repositories.yml) | Updates configured repositories through an Azure DevOps wrapper. || Pipeline updates | Azure DevOps | [`21-update-pipelines.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/21-update-pipelines.yml) | Updates configured Azure Pipelines definitions. |
| Terraform removal | GitHub Actions | [`10-remover-terraform.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/10-remover-terraform.yml) | Removes Terraform-managed resources. |
| Terraform and ARM removal | Azure DevOps | [`10-remover-terraform.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/10-remover-terraform.yml) and [`11-remover-arm-fallback.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/11-remover-arm-fallback.yml) | Provides Terraform removal and an Azure Resource Manager fallback. |
| Control-plane removal | GitHub Actions | [`12-remove-control-plane.yml`](https://github.com/Azure/sap-automation-gh-bootstrap/blob/0ee1260a6bce5137cdf295386ad9e32ef5c8bd1d/.github/workflows/12-remove-control-plane.yml) | Removes control-plane resources. |
| Control-plane removal | Azure DevOps | [`12-remove-control-plane.yml`](https://github.com/Azure/sap-automation-bootstrap/blob/fd94e68d96a5827707d08bcb622d44e8a80f789b/pipelines/12-remove-control-plane.yml) | Wraps the core control-plane removal template. |
| Local recovery and removal | Local | [`advanced_state_management.sh`](../deploy/scripts/advanced_state_management.sh), [`remove_controlplane.sh`](../deploy/scripts/remove_controlplane.sh), [`remove_control_plane_v2.sh`](../deploy/scripts/remove_control_plane_v2.sh), [`remover.sh`](../deploy/scripts/remover.sh), and [`remover_v2.sh`](../deploy/scripts/remover_v2.sh) | State, recovery, and removal assets exist. Detailed guidance must validate supported entry points and safe ordering. |

## Open validation questions

The following questions must be resolved before detailed journey guidance
labels one option as current or supported:

- What is the intended public distinction between the Azure DevOps software
  download wrapper variants?
- Which local established and v2 entry points are supported for each release?
- What is the approved support boundary and support channel?

Do not infer these answers from filenames. Record owner confirmation and the
validated release when a question is resolved.
