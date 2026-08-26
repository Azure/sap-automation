# Release Notes: SDAF 3.23.0.0

## Functional Differences

### 1. Application-tier storage and mount handling
- Added explicit support for placing application-tier `/usr/sap` on shared
  Azure Files or Azure NetApp Files storage while retaining local storage when
  no shared mount is configured.
- Refactored simple-mount handling for Azure Files and Azure NetApp Files,
  including NFS identity-map preparation and cleanup of local `/usr/sap`
  content before a shared mount replaces it.

### 2. SAP quality assurance
- Integrated the SAP Testing Automation Framework into Azure DevOps and local
  execution flows for configuration checks and SAP functional tests.
- Added selectable database high availability, central services high
  availability, and Azure Backup functional-test paths, with optional test
  group and test case filtering.
- Added result collection and operational documentation for running and
  reviewing quality-assurance tests against deployed SAP systems.

### 3. Utility storage immutability
- Added optional container-level WORM retention policies for utility blob
  containers.
- Added optional account-level versioning and version-level immutability,
  including validation for supported account types, retention periods, and
  irreversible lock acknowledgement.

### 4. Deployment and setup reliability
- Corrected Azure region-code handling, GitHub Actions setup behavior, private
  endpoint subnet policy configuration, and SAP-system deployment exit-code
  propagation.
- Corrected the `sync_deployer.sh` help example to use the supported
  `--subscription` option.

### 5. AI-assisted SDAF guidance
- Added an optional SDAF skills plugin for GitHub Copilot CLI, Claude Code, and
  Gemini CLI, covering deployment readiness, infrastructure stages, SAP
  installation, quality assurance, high availability, state management,
  removal, and failure triage.
- Added routing evaluations and validation automation for the shipped skills.


## Notes

- SDAF release version is `3.23.0.0` across the deployment version file,
  Ansible input template, and Azure DevOps PowerShell utilities.