# SAP Deployment Automation Framework documentation

Use this hub to choose an SAP Deployment Automation Framework (SDAF)
execution model and locate the repository that owns each procedure or asset.
Repository documentation describes the current implementation in the source
repositories.

## Start a deployment

1. Read [Choose an SDAF deployment option](deployment-options.md).
2. Select GitHub Actions, Azure DevOps, or local scripted execution.
3. Open the owning repository or source directory listed for that model.
4. Review the prerequisites and configuration-generation behavior before you
   deploy resources.
5. Use the shared samples repository when you need Terraform examples, SAP
   application definitions, or BOM files.

After these steps, you have selected an execution model and identified the
configuration and automation assets for the first deployment stage.

| Goal | Documentation or source |
| --- | --- |
| Compare execution models | [Choose an SDAF deployment option](deployment-options.md) |
| Understand repository ownership | [SDAF repositories](repositories.md) |
| Use GitHub Actions | [`Azure/sap-automation-gh-bootstrap`](https://github.com/Azure/sap-automation-gh-bootstrap) |
| Use Azure DevOps | [Start with Azure DevOps](deployment-options.md#azure-devops) |
| Run SDAF directly | [`deploy/scripts`](../deploy/scripts/) infrastructure scripts and [`deploy/ansible`](../deploy/ansible/) software-download and installation wrappers |
| Find Terraform samples and SAP BOMs | [`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples) |

## Understand the framework source

The core repository contains the implementation used by every execution
model:

- [`deploy/terraform`](../deploy/terraform/) contains the Terraform root and
  reusable modules.
- [`deploy/ansible`](../deploy/ansible/) contains the numbered playbooks and
  roles for operating-system, database, and SAP configuration.
- [`deploy/scripts`](../deploy/scripts/) contains local entry points and
  pipeline helper scripts.
- [`deploy/pipelines`](../deploy/pipelines/) contains the pipeline templates
  consumed by wrapper repositories.
- [`Webapp`](../Webapp/) contains the configuration web application.

## Maintain the documentation

Use the following references when you add or review repository guidance:

- [Documentation conventions](documentation-conventions.md) defines the
  common journey, page structure, terminology, and validation rules.
- [Documentation source map](documentation-source-map.md) records the source
  assets used to validate execution-model capabilities.
- [Contributing guidelines](../CONTRIBUTING.md) explains how to propose a
  repository change.

## Get help or report a problem

- Search or open a
  [GitHub issue](https://github.com/Azure/sap-automation/issues) for a bug or
  feature request.
- Follow [SECURITY.md](../SECURITY.md) to report a security vulnerability.
- Include the execution model, repository version, deployment stage, command
  or automation name, configuration path, and relevant error output when you
  report a problem.
