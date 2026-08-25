# Run SDAF locally

Use this journey to run the SAP Deployment Automation Framework (SDAF)
directly from an operator-managed host. Local execution is an equal execution
model to GitHub Actions and Azure DevOps. It uses the same Terraform modules,
Ansible playbooks, configuration model, and remote state.

Local execution does not include a hosted stage generator. Prepare and review
configuration from the
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples)
repository, the SDAF Web application where applicable, or direct editing.

## Complete the journey

1. [Review prerequisites](01-00-prerequisites.md).
2. [Prepare the execution environment](02-00-prepare-execution-environment.md).
3. [Deploy the control plane](03-00-control-plane.md).
4. [Deploy a workload zone](04-00-workload-zone.md).
5. [Deploy an SAP system](05-00-sap-system.md).
6. [Download software and run installation](06-00-software-and-installation.md).
7. [Operate, recover, and remove the deployment](07-00-operations.md).

Within stage 7, use
[Validate a local deployment with quality assurance tests](07-10-quality-assurance.md)
to run configuration checks and SAP functional tests against a deployed
system.

Use [Troubleshoot local execution](troubleshooting.md) when a command stops or
the observed state differs from the expected state.

## Understand the local automation boundary

The operator owns:

- The execution host and installed tools.
- The checked-out SDAF version.
- The configuration repository or working directory.
- Azure sign-in and access controls.
- Review and approval before each state-changing command.
- Retention of configuration, state metadata, and logs.

SDAF automation owns:

- Terraform initialization, planning, application, and output generation.
- Control-plane state bootstrap and migration to Azure Storage.
- Workload-zone and SAP-system access to remote state.
- Generation of Ansible inventory and `sap-parameters.yaml`.
- BOM-driven software download and numbered Ansible playbook execution.
- Quality assurance framework installation and test execution against a
  deployed SAP system.

## Select a script family

This release contains established and v2 implementations. The repository does
not identify either family as preferred, recommended, or legacy. Select the
family named by your release guidance, validate its `--help` output against
the checked-out version, and use that family consistently for deployment and
removal.

| Outcome | Established entry point | v2 entry point | Source-backed distinction |
| --- | --- | --- | --- |
| Deploy the complete control plane | [`deploy_controlplane.sh`](../../deploy/scripts/deploy_controlplane.sh) | [`deploy_control_plane_v2.sh`](../../deploy/scripts/deploy_control_plane_v2.sh) | Both orchestrate deployer and library deployment. The established script invokes standalone scripts. The v2 script sources v2 functions. |
| Deploy only the deployer | [`install_deployer.sh`](../../deploy/scripts/install_deployer.sh) | [`install_deployer_v2.sh`](../../deploy/scripts/install_deployer_v2.sh) | Component-level control-plane entry points. |
| Deploy only the library | [`install_library.sh`](../../deploy/scripts/install_library.sh) | [`install_library_v2.sh`](../../deploy/scripts/install_library_v2.sh) | Component-level control-plane entry points. |
| Deploy a workload zone | [`install_workloadzone.sh`](../../deploy/scripts/install_workloadzone.sh) | No separate v2-named workload-zone entry point | The v2 installer accepts `--type sap_landscape`, but do not substitute it unless release guidance selects that path. |
| Deploy an SAP system | [`installer.sh`](../../deploy/scripts/installer.sh) | [`installer_v2.sh`](../../deploy/scripts/installer_v2.sh) | Both accept a deployment type and a parameter file. Their option names and state variables differ. |
| Remove an SAP system or workload zone | [`remover.sh`](../../deploy/scripts/remover.sh) | [`remover_v2.sh`](../../deploy/scripts/remover_v2.sh) | Use the matching family and deployment type. |
| Remove the control plane | [`remove_controlplane.sh`](../../deploy/scripts/remove_controlplane.sh) | [`remove_control_plane_v2.sh`](../../deploy/scripts/remove_control_plane_v2.sh) | Both remove library and deployer resources. |

The procedural commands in this journey show the established family because
its stage-specific entry points are explicit. If your release guidance selects
the v2 family, use the v2 `--help` output and do not copy established-family
options unchanged.

## Configuration and state layout

Keep deployment configuration outside the SDAF source checkout. A typical
configuration root contains:

```text
WORKSPACES/
├── DEPLOYER/<control-plane>-INFRASTRUCTURE/
├── LIBRARY/<environment>-<location>-SAP_LIBRARY/
├── LANDSCAPE/<workload-zone>-INFRASTRUCTURE/
└── SYSTEM/<SAP-system>/
```

Each leaf directory contains its same-named `.tfvars` file. Scripts also
create or update:

- `.terraform/` beside the parameter file for Terraform working data and
  backend metadata.
- `.sap_deployment_automation/` under `CONFIG_REPO_PATH` for persisted
  environment metadata.
- `apply_output.log` or `apply_output.json` in the current stage directory.
- Stage summaries and generated Ansible files where the source module defines
  them.

Do not commit secrets, private keys, Terraform state, `.terraform/`, or
`.sap_deployment_automation/` to source control.

## Source validation baseline

This journey was validated against `Azure/sap-automation` commit
`fe6a307d1c9d0dee81d1dfc486265276aed3b03a` on
`release/july-2026`. Revalidate commands and capability statements before you
use another release.
