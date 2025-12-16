# Release PR: SDAF 3.18.0.0

## Problem

The SAP Deployment Automation Framework required several critical improvements across multiple dimensions:

1. **DevOps Integration Gaps** - Limited support for GitHub Actions workflows and inconsistent Azure App Configuration handling across deployment pipelines
2. **Platform Support** - Missing support for Ubuntu 25.04 and incomplete Oracle Grid infrastructure provisioning
3. **Deployment Reliability** - Key vault reference inconsistencies in managed DevOps scenarios causing deployment failures
4. **Configuration Management** - Fragmented approach to storing and retrieving deployment parameters across control plane and workload zones
5. **Infrastructure Gaps** - Missing marketplace plan configurations for observer VMs and incomplete Azure App Configuration integration

## Solution

### DevOps & Automation
- **GitHub Actions Integration**:
  - New Python script (`New-SDAFGitHubActions.py`) for automated SDAF GitHub Actions setup with retry logic and improved error handling
  - Docker container support for GitHub Actions with optimized Dockerfile and container build workflow
  - Updated Terraform version to 1.14.0 across repository
- **Azure App Configuration**: Implemented comprehensive Terraform modules for App Configuration resources across SAP landscape and library modules with private DNS zone management
- **Pipeline Script Refactoring**: Enhanced v2 pipeline scripts with platform-agnostic functions, improved variable management, and ECC PGP key generation support

### Infrastructure & Platform Support
- **Ubuntu 25.04 Support**: Updated deployment scripts and Terraform configurations to handle Ubuntu 25.04 ("plucky"), including Azure CLI repository adjustments
- **Oracle Grid Enhancements**: Added CRS data/admin directories with dynamic permissions, implemented logical sector size handling for disk configurations
- **Observer VM Marketplace Plans**: Added dynamic plan configuration blocks to properly provision marketplace-based observer VMs

### Deployment Reliability
- **Key Vault Handling**: Refactored key vault ID retrieval to use control plane naming conventions consistently across all deployment scripts
- **State Management**: Improved Terraform state migration handling with proper parameter sourcing and subscription ID management
- **Variable Management**: Streamlined APPLICATION_CONFIGURATION_ID and APPLICATION_CONFIGURATION_NAME handling with proper fallbacks and validation

### Configuration & Usability
- **Distribution Variables**: Made distribution IDs available across all Ansible playbooks as group variables for improved consistency
- **SUSE HA Optimization**: Set default vm.swappiness to 10 (down from 60) for SUSE HA clusters to improve performance
- **Parameter Handling**: Refactored parameter passing to use dict with zip for improved code clarity
- **Debug Improvements**: Enhanced error messages, logging, and conditional checks across deployment scripts

### Bug Fixes
- Fixed SAP_PARAMS handling in v1 Ansible script to properly handle file paths
- Corrected conditional logic for App Configuration private DNS zones and virtual network links
- Resolved empty Terraform state file handling in installer scripts
- Fixed subscription ID extraction and environment variable exports

## Tests

### Prerequisites
- Azure subscription with appropriate permissions
- Ubuntu 25.04 test environment (if testing platform support)
- GitHub repository with Actions enabled (for GitHub Actions testing)

### Test Scenarios

**1. GitHub Actions Setup**
```bash
cd deploy/scripts/py_scripts/SDAF-GitHub-Actions
python New-SDAFGitHubActions.py
# Verify: GitHub Actions workflows created, repository variables configured, Terraform version set to 1.14
```

**2. Ubuntu 25.04 Deployment**
```bash
# Deploy control plane on Ubuntu 25.04
./deploy_control_plane_v2.sh --parameterfile <config_file>
# Verify: Azure CLI repository correctly configured, Terraform 1.14.0 installed
```

**3. Azure App Configuration Integration**
```bash
# Deploy landscape with App Configuration
terraform plan -var-file=<landscape_config>
# Verify: App Configuration resources created, private DNS zones configured, key-value pairs populated
```

**4. Oracle Grid Setup**
```bash
# Deploy SAP system with Oracle database
# Verify: CRS data/admin directories created with correct permissions, logical sector sizes applied
```

**5. Managed DevOps Scenario**
```bash
# Deploy using v2 pipeline scripts
./deploy/scripts/pipeline_scripts/v2/01-webapp-configuration.sh
# Verify: Key vault references resolved correctly, APPLICATION_CONFIGURATION_ID retrieved
```

**6. Observer VM with Marketplace Image**
```bash
# Deploy SAP system with observer VM using marketplace image
# Verify: Plan block included in Terraform configuration, VM deploys successfully
```

## Notes

### Breaking Changes
- None identified - this release maintains backward compatibility with existing deployments

### Migration Considerations
- Existing deployments can upgrade in place
- New Terraform 1.14.0 version requires validation of provider compatibility in custom modules
- App Configuration integration is additive and does not affect existing deployments without App Configuration

### Known Limitations
- Docker container support for GitHub Actions is experimental and requires container registry access
- Ubuntu 25.04 support is based on pre-release repositories which may change

### Dependencies Updated
This release includes multiple dependency version bumps:
- actions/checkout: 5.0.0 → 5.0.1
- actions/upload-artifact: 4.6.2 → 5.0.0 (major version bump)
- github/codeql-action: 4.31.1 → 4.31.3
- actions/dependency-review-action: 4.8.1 → 4.8.2
- step-security/harden-runner: 2.13.1 → 2.13.2
- Azure.ResourceManager.Compute: 1.12.0 → 1.13.0
- System.Runtime.Caching: 9.0.10 → 10.0.0 (major version bump)
- NuGet.Packaging: 6.14.0 → 7.0.0 (major version bump)
- dotnet-ef: 9.0.6 → 10.0.0 (major version bump)

### Contributor Recognition
This release includes contributions from:
- Kimmo Forss (@kimforss)
- Nadeen Noaman (@nnoaman)
- Copilot (code review and suggestions)
- hdamecharla (@hdamecharla)
 