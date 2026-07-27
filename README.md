<!-- Copyright (c) Microsoft Corporation. -->
<!-- Licensed under the MIT License. -->

# SAP Deployment Automation Framework

The SAP deployment automation framework on Azure is an open-source orchestration tool for deploying, installing and maintaining SAP environments. You can create infrastructure for SAP landscapes based on SAP HANA and NetWeaver with AnyDB on any of the SAP-supported operating system versions and deploy them into any Azure region.

The framework uses Terraform for infrastructure deployment, and Ansible for the operating system and application configuration.

![Ansible Lint](https://github.com/Azure/sap-automation/workflows/Ansible%20Lint/badge.svg)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/azure/sap-automation.svg)](http://isitmaintained.com/project/azure/sap-automation "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/azure/sap-automation.svg)](http://isitmaintained.com/project/azure/sap-automation "Percentage of issues still open")
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/sap-automation/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/sap-automation)

## Choose how to run SDAF

SDAF supports three execution models. Each model deploys the same framework
components, but the setup, configuration generation, identity, and approval
processes differ.

| Execution model | Use this path when | Start here |
| --- | --- | --- |
| GitHub Actions | Your deployment configuration and automation run from GitHub repositories and workflows. | [Review the GitHub Actions execution model](docs/deployment-options.md#github-actions) |
| Azure DevOps | Your organization uses Azure Repos, Azure Pipelines, service connections, variable groups, and agent pools. | [Review the Azure DevOps execution model](docs/deployment-options.md#azure-devops) |
| Local or scripted execution | You run the SDAF scripts directly from a workstation, deployment host, or other automation environment. | [Review the local execution model](docs/deployment-options.md#local-or-scripted-execution) |

For selection criteria and capability differences, see
[Choose an SDAF deployment option](docs/deployment-options.md).

## Use samples and SAP software definitions

All three execution models use shared configuration examples and SAP software
definitions. The
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples)
repository contains:

- Terraform examples under `Terraform/WORKSPACES`.
- SAP application definitions under `SAP`.
- Bill of materials (BOM) files under `BOM`.
- Ansible sample inputs under `Ansible`.

## Understand the deployment lifecycle

Complete the SDAF lifecycle in dependency order:

1. Plan Azure architecture, networking, identity, quota, sizing, and cost.
2. Bootstrap the selected execution environment.
3. Configure, review, deploy, and validate the control plane.
4. Configure, review, deploy, and validate a workload zone.
5. Configure, review, deploy, and validate an SAP system.
6. Download SAP software and run operating-system, database, and SAP
   installation.
7. Operate, update, recover, or remove the environment.

> [!WARNING]
> SDAF creates billable Azure resources and changes shared infrastructure.
> Review every Terraform plan, confirm state access, and validate destructive
> operations before approval.

## Find documentation

Use the [repository documentation hub](docs/index.md) for current
repository-owned guidance. The hub explains repository responsibilities,
deployment choices, documentation conventions, and the source used to validate
capability statements.

Detailed platform procedures remain with the repository that owns the
workflows, pipelines, scripts, or samples. For repository boundaries, see
[SDAF repositories](docs/repositories.md).

## Contributing

Before you contribute, review the [contributing guidelines](CONTRIBUTING.md).

Use [GitHub issues](https://github.com/Azure/sap-automation/issues/) for
feature requests and bugs. Report security vulnerabilities by following
[SECURITY.md](SECURITY.md).

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.


> Copyright (c) Microsoft Corporation.
> Licensed under the MIT License.
> See [LICENSE](LICENSE) for more information.
