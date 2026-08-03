# Release Notes: SDAF 3.22.0.0

## Functional Differences

### 1. GitHub Actions and OpenID Connect
- Added Azure Government support to the GitHub Actions setup flow, including
  cloud-specific OIDC environment, audience, and Terraform settings.
- Added repository-aware OIDC subject handling. Setup now preserves existing
  federated credentials and uses GitHub's reported subject prefix when no
  explicit subject format or subject override is supplied.
- Added US Government regions (`USAR`, `USTE`, and `USVI`) to configuration,
  pipeline choices, and sample-deployer configuration generation.

### 2. Azure infrastructure, storage, and recovery
- Added cloud-specific Azure Storage endpoint handling and configurable storage
  routing preferences.
- Improved workload-zone remote-state persistence, force-reset recovery, role
  assignment ID normalization, and private endpoint policy configuration.
- Added Terraform plan-shape and validation tests for configurable private
  endpoint policies, separate storage subnets, and utility VM zone placement.
- Expanded Terraform input validation for storage subnet and zone-distribution
  configurations.
- Added Azure Government parameters to Pacemaker fencing configuration and
  strengthened fencing service-principal validation.

### 3. SAP high availability and operating system support
- Added SLES 16 support and corrected SSH drop-in configuration handling.
- Added NVMe shared-disk support for SBD, including longer reboot and
  connection timeouts during NVMe changes.
- Corrected the RHEL SAP HANA HA/DR provider configuration and installed SBD
  prerequisites for the supported clustered deployment paths.

### 4. Documentation and local execution
- Added the central SDAF documentation hub, architecture and supportability
  documentation, and the local execution journey.

## Notes

- SDAF release version is `3.22.0.0` in both
  `deploy/configs/version.txt` and the Ansible input template.
