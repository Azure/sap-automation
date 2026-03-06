# Release Notes: SDAF 3.19.0.0

## Problem

Following the SDAF 3.18.0.0 (January 2026) release, several areas required critical fixes and enhancements:

1. **Azure Files NFS Encryption in Transit** - AFS NFS mount configurations needed end-to-end support for Encryption in Transit (EiT), including Terraform variable propagation, Ansible mount options, and repository/package setup for the `aznfs` client
2. **Repository & Package Management** - Microsoft repository URLs, GPG key handling, and zypper task reliability on SUSE required significant fixes
3. **Terraform Upgrade** - Terraform needed to be updated to 1.14.5 across all pipeline scripts and configurations
4. **Platform Gaps** - Missing support for Red Hat 10.0, SLES SAP 16, and NVMe swap dependencies
5. **Authentication & Provider Issues** - Service Principal login, azurerm provider MSI/SPN configuration, and GitHub Actions SPN export needed fixes

## Solution

### Azure Files — NFS Encryption in Transit
- Added `AFS_enable_encryption_in_transit` variable propagation through `sap_landscape`, `sap_system`, and `sap_deployer` Terraform modules
- Storage accounts conditionally disable HTTPS-only traffic for SAP mount storage when EiT is enabled
- ANF export policy rules now conditionally use VNet address space based on infrastructure settings
- NFS mount options (`fstype`, `_netdev`) are now driven by variables (`nfs_fs_type`, `use_eit_for_afs`) instead of being hardcoded
- Removed `nolock` option from AFS NFS mount configurations
- Mount options are consistently applied across standard mounts, simple mounts, and Oracle observer mounts
- Added `AFS_enable_encryption_in_transit` to Webapp `LandscapeModel`, `LandscapeDetails.json`, and `LandscapeTemplate.txt`

### Repository & Package Management
- Added Microsoft GPG public key download and import tasks for both RHEL and SUSE
- Removed `aznfs` package from `os-packages.yaml` (now handled through EiT setup tasks directly)
- Refactored Microsoft Production repository entries in `repos.yaml` to use direct URLs
- Zypper tasks reworked for reliability: `ZYPP_LOCK_TIMEOUT`, `disable_gpg_check`, `auto_import_keys`, proper `become`/`become_user` directives, and use of `community.general.zypper_repository`
- Fixed Microsoft packages repository RPM download URLs for both RHEL and SUSE

### Infrastructure & Platform Support
- **Terraform 1.14.6**: Updated across all v1/v2 pipeline scripts, PowerShell utilities, GitHub Actions configs, deployer bootstrap, and URL configurations (32 files)
- **Red Hat 10.0**: Added RHEL 10.0 and RHEL 10.0 HA images to `VM-Images.json`
- **NVMe swap**: Added NVMe swap dependency installation tasks for both RHEL and SUSE in the swap configuration role
- **v6 SKU support**: Added support for the new v6 SKUS
- **SUSE subscription & disk controller**: Added new parameters for SUSE subscription and disk controller types in `SystemModel` and related Webapp files

### Pacemaker / High Availability
- Refactored NFS mount options and cluster commands for consistency across RedHat and SUSE in the SCS/ERS pacemaker role
- `clus_nfs_options` fact now correctly handles AFS vs ANF provider differences and appends `_netdev` only for NFSv4.1 with EiT enabled
- 'SAPHanaSR-angi' support for SLES based deployments, [What is SAPHanaSR-angi?](https://www.suse.com/c/what-is-saphanasr-angi/)

### Bug Fixes
- **Terraform role assignment typo**: Fixed resource reference typo in `role_assignments.tf` for the deployer module
- **Service Principal login**: Fixed `az login` for Service Principal across 7 pipeline/helper scripts
- **azurerm provider MSI/SPN**: Refactored `sap_landscape` provider to conditionally set `use_msi` and `use_spn`
- **GitHub Actions SPN export**: Added conditional `TF_VAR_use_spn` export based on `USE_MSI` variable
- **SUSE subscription ID default**: Fixed default value handling for `suse_subscription_id` in SUSE package activation tasks
- **passlib installation**: Fixed passlib installation for Red Hat controllers — moved from missing task → pip install → OS package manager with pip fallback → works for all OS families
- **compat-sap-c++ versioning**: Updated package spec to use wildcard versioning in `os-packages.yaml`
- **AFS mount options formatting**: Multiple fixes to AFS mount options formatting and configuration in the 2.6.0 AFS Mounts task
- **Scope addition wording**: Fixed wording in scope addition instructions across PowerShell scripts
- **HTTPS-only on SAP storage**: Disabled HTTPS-only traffic specifically for SAP mount storage account (required for NFS)
- **For HANA scale out scenario**: Add the identities of all nodes to the resource group with permissions to start fencing


## Tests

### Prerequisites
- Azure subscription with appropriate permissions
- RHEL 8.x/9.x or SLES 15 SP4+ test environment
- GitHub repository with Actions enabled (for GitHub Actions testing)

### Test Scenarios

**1. AFS Encryption in Transit**
```bash
# Deploy landscape with AFS_enable_encryption_in_transit = true
# Verify: NFS mounts use NFSv4.1 with _netdev option, aznfs packages installed, Microsoft GPG keys imported
```

**2. Terraform 1.14.5 Upgrade**
```bash
# Run any deployment pipeline
# Verify: Terraform version 1.14.5 is downloaded and used
```

**3. Red Hat 10 / SLES SAP 16 Deployments**
```bash
# Deploy system with RHEL 10.0 or SLES SAP 16 image
# Verify: OS packages install correctly, services configured, pacemaker cluster operational
```

**4. Service Principal Authentication**
```bash
# Run pipeline with Service Principal authentication
# Verify: az login succeeds, TF_VAR_use_spn set correctly
```

## Notes

### Breaking Changes
- None identified — all changes are backward compatible. The AFS encryption in transit feature is opt-in via the `AFS_enable_encryption_in_transit` parameter.

### Migration Considerations
- Terraform 1.14.5 is now required; ensure deployer environments are updated
- If using AFS with encryption in transit, set `AFS_enable_encryption_in_transit = true` in landscape configuration
- Microsoft repository URLs for RHEL and SUSE have been updated; existing deployments will pick up the new URLs on next repository configuration run
- The `aznfs` package is no longer installed via `os-packages.yaml`; it is now handled through the EiT setup tasks directly

### Known Limitations
- AFS encryption in transit is only supported with NFSv4.1 volumes
- Red Hat 10.0 and SLES SAP 16 support is new and should be validated in non-production environments first

### Dependencies Updated
This release includes multiple dependency version bumps:
- actions/checkout: 6.0.1 → 6.0.2
- aquasecurity/trivy-action: 0.33.1 → 0.34.0
- step-security/harden-runner: 2.14.0 → 2.14.2
- github/codeql-action: 4.31.10 → 4.32.3
- Azure.ResourceManager.Network: 1.14.0 → 1.15.0
- System.Runtime.Caching: 10.0.2 → 10.0.3
- NuGet.Packaging: 7.0.1 → 7.3.0
- dotnet-ef: 10.0.2 → 10.0.3

### Contributor Recognition
This release includes contributions from:
- Kimmo Forss (@kimforss)
- Nadeen Noaman (@nnoaman)
- Hemanth Damecharla (@hdamecharla)
 