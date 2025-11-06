# Changelog - Release August 2025

## Version 3.17.0.0

### Infrastructure & Terraform

#### Provider Updates
- Updated AzureRM provider compatibility for deprecated properties
- Changed `enable_rbac_authorization` to `rbac_authorization_enabled` in Key Vault resources
- Updated ANF export policy rules to use `protocol` instead of `protocols_enabled`
- Changed `enable_automatic_updates` to `automatic_updates_enabled` for virtual machines
- Changed `enable_floating_ip` to `floating_ip_enabled` in load balancer rules
- Updated variable naming from `dual_nics` to `dual_network_interfaces` for consistency

#### Disk and Storage Management
- Enhanced backup disk handling with ZRS storage type detection and zone assignment logic
- Standardized disk IOPS/MBPS configuration for UltraSSD_LRS and PremiumV2_LRS disk types
- Improved proximity placement group logic for Windows VMs
- Optimized Ansible disk definitions
- Fixed disk attachment reference for observer VMs in HANA scale-out scenarios
- Added observer VM data disk attachment for proper cluster setup

#### Network Configuration
- Refactored subnet ID handling across multiple modules for improved clarity
- Fixed subnet CIDR value trimming in output files
- Improved storage subnet output logic with better fallback handling
- Enhanced NSG count logic for application and web subnets
- Updated SAP web dispatcher subnet count condition
- Fixed variable references in network interface configurations

#### Key Vault Management
- Added Key Vault Administrator and Secrets Officer role assignments with appropriate conditions
- Refactored role assignment dependencies for improved clarity
- Updated access policy conditions to include permission assignment options
- Fixed key vault secret name assignment to use local variables
- Improved secret existence checks using user ARM ID

#### Resource Naming and Variables
- Added `naming_new` variable to variables_global.tf for additional resource naming
- Introduced `custom_random_id` for resource name suffixes
- Removed DEPLOYER_RANDOM_ID and LIBRARY_RANDOM_ID dependencies
- Added resource group name and ID to locals
- Improved handling of unset/null variables

### Azure DevOps Pipeline Enhancements

#### Pipeline Refactoring
- Refactored deployment YAML files to enhance parameter definitions
- Streamlined variable management across control plane, workload zone, and system deployment
- Bumped Terraform version from 1.12.2 to 1.13.3 in multiple scripts
- Corrected indentation for Terraform installation tasks
- Fixed path references and updated playbook options for consistency
- Specified version for `community.general` collection in Ansible Galaxy installation

#### Variable Management
- Separated v1 and v2 pipeline configurations
- Updated variable group construction to use DEPLOYER_ENVIRONMENT
- Ensured 03-sap-system-deployment uses VARIABLE_GROUP_ID correctly
- Fixed control plane name and variable group construction
- Added Storage Account name and subscription to installation pipeline
- Removed unused DEPLOYER_KEYVAULT variable from control plane deployment

#### Authentication and Identity
- Updated agent PAT variable handling (AccessToken vs PAT)
- Enhanced Azure login handling with visibility controls
- Added Azure account information display on Terraform apply failure
- Improved Managed Identity support with ManagedIdentityId parameter
- Updated role assignment commands to use ARM_OBJECT_ID

#### Script Improvements
- Created upgrade scripts for Control Plane and Workload Zone variable groups
- Added Copy-AzDevOpsVariableGroupVariable function
- Implemented Set-AdoManagedIdentityCredentials and Set-AdoSPNCredentials functions
- Refactored installer script calls for improved error handling
- Enhanced exit handling to use return codes for better error reporting

### Oracle Database Support

#### Oracle ASM Enhancements
- Added support for ASMLib v3
- Added support for Oracle UEK7 (Unbreakable Enterprise Kernel 7)
- Removed unused oracle_asm_sector_size variable
- Updated file permissions to use string format for mode in Oracle ASM tasks
- Added temporary directory creation and debug messages for DB SID and Oracle version
- Enhanced ASM filesystem structure for primary and standby databases

#### Oracle Data Guard Configuration
- Enhanced environment variable management (ORACLE_HOME, ORACLE_SID, ORACLE_BASE)
- Implemented shutdown/restart procedures with improved error handling
- Updated duplication and finalization tasks with better status checks
- Streamlined SSFS file handling and cleanup tasks
- Standardized SQL*Plus syntax and improved verification logic
- Added checks for ORA-specific errors and optimized post-deployment steps
- Added pause task to stabilize Data Guard configuration during finalize process
- Enhanced error handling for broker start and verification process
- Created comprehensive Data Guard templates for primary and standby configurations
- Removed obsolete 05-install-observer.yaml task file

#### Oracle Installation Improvements
- Fixed SAPINST parameter file handling for Oracle installations
- Ensured correct EXPORT vs DB_EXPORT directory handling
- Fixed oracle-postprocessing supported_tiers check validation
- Added checks for zombie standby processes
- Implemented cleaning of orphaned shared memory segments
- Updated post-installation tasks to accommodate Oracle ASM configurations

### SAP Installation and Configuration

#### HANA Pacemaker and High Availability
- Enhanced HANA Pacemaker scale-out Ansible tasks
- Removed unnecessary manual start tasks for HANA database in cluster preparation
- Updated Suse cluster scale-out tasks for proper resource and constraint configuration
- Refactored HANA Pacemaker configuration to use blockinfile for colocation constraints
- Improved cleanup process for HANA cluster configuration
- Added permission settings for /hana/shared directory in scale-out tasks
- Enhanced post-provision reporting for SBD devices status and hook script verification

#### SAP Application Server
- Updated task names for clarity in 5.3 application server installation role
- Removed unnecessary backward compatibility checks
- Improved error handling and logging for database load balancer checks
- Standardized comments and task descriptions across various roles
- Added default configuration variables for Windows disk setup

#### Database Configuration
- Added preparation tasks for SAP HANA scale-out installation
- Enhanced backend pool association for SAP HANA scale-out HA scenarios
- Improved Terraform module outputs to include observer shared disks
- Adjusted subnet configurations for high availability
- Fixed ANF volume export policy rule configurations

### NVMe Support and Disk Management

#### NVMe Enhancement
- Enhanced Azure NVMe udev rules for compatibility with older distributions
- Improved namespace ID (NSID) handling and device identification methods
- Added fallback logic to extract NSID from ID_PATH or /sys/class/block/<device>/nsid
- Enhanced LUN calculator for proper device identification
- Updated NVMe detection logic across RHEL and SUSE platforms
- Refactored task names for consistency in NVMe support scripts
- Improved NVMe timeout handling and GRUB configuration
- Streamlined preflight checks with improved debug output

### PowerShell and Web Application Updates

#### SDAF Utilities Enhancements
- Added Get-SDAFUserAssignedIdentity function to retrieve user-assigned identities
- Updated SDAFUtilities.psd1 to export new functions
- Modified New-SDAFADOProject to include ControlPlaneName parameter
- Enhanced New-SDAFADOWorkloadZone with WorkloadZoneName parameter
- Added ControlPlaneSubscriptionId parameter to New-SDAFADOWorkloadZone
- Improved Managed Identity client ID retrieval and role assignment logic
- Enhanced role assignment logging for Managed Identity

#### Web Application Updates
- Added validation for SID length
- Updated deployment flags and VM image SKU handling
- Created new web app configuration scripts for v1 and v2
- Added Red Hat and Oracle Linux images
- Updated Windows Server 2025 details
- Enhanced workload zone and environment handling in models and views
- Refactored LandscapeModel to initialize workload_zone_id with empty string
- Improved formatting and consistency in LandscapeController

### Ansible Configuration and Playbooks

#### Ansible Core Updates
- Added install script for Ansible with dependency management and version control
- Refactored JMESPath installation logic for clarity and conditional execution
- Enabled stdout callback for YAML output
- Improved callback formatting in ansible.cfg
- Updated package references to latest versions

#### Template and Task Updates
- Updated hosts.j2 Ansible template
- Removed redundant lines and improved readability across playbooks
- Streamlined controller constructors
- Updated user account definitions for Oracle with accurate comments and roles
- Fixed run_once and delegate_to usage in AFS mount tasks
- Updated SAP SID variable in package update tasks

### Dependency Updates

#### GitHub Actions
- Bumped github/codeql-action from 3.29.8 to 4.31.1
- Bumped actions/checkout from 4.2.2 to 5.0.0
- Bumped actions/dependency-review-action from 4.7.1 to 4.8.1
- Bumped actions/setup-python from 5.6.0 to 6.0.0
- Bumped aquasecurity/trivy-action from 0.31.0 to 0.33.1
- Bumped ossf/scorecard-action from 2.4.2 to 2.4.3
- Bumped step-security/harden-runner from 2.13.0 to 2.13.1

#### Azure SDK and Libraries
- Bumped Azure.Identity from 1.15.0 to 1.17.0
- Bumped Azure.ResourceManager.Compute from 1.11.0 to 1.12.0
- Updated Azure.ResourceManager.Network package version
- Updated Azure.ResourceManager.Storage package version
- Bumped Microsoft.Identity.Web and Microsoft.Identity.Web.UI packages
- Updated multiple Azure and Microsoft package references in SDAFWebApp.csproj

#### .NET Tools
- Bumped dotnet-ef from 9.0.6 to 9.0.9

### Bug Fixes and Improvements

#### Configuration Fixes
- Fixed version comparison for cloud-netconfig-azure in Pacemaker tasks
- Corrected return value handling in Terraform plan execution
- Fixed variable name in outputs.tf for disk definitions
- Updated disk output definitions to use dynamic VM names
- Fixed syntax error in subnet ID parsing
- Removed redundant deployment variable

#### Script and Template Fixes
- Fixed deployer environment file handling for v1 and v2 scripts
- Improved deployer environment file path construction
- Enhanced error checking for environment configuration files
- Removed unnecessary package 'dos2unix' from configure_deployer.sh template
- Fixed key vault existence checks

#### Sybase Configuration
- Refactored Sybase sizes configuration storage definitions
- Added accelerated networking for 512, 1024, and 2048 configurations
- Updated lun_start values for storage configurations
- Specified Python version as 3.10 in GitHub Actions workflow

#### DNS and Private Link
- Refactored count conditions for DNS zone links (vault_agent, blob_agent, vnet_mgmt_blob-agent)
- Improved clarity and reliability of DNS zone configurations

### Documentation and Code Quality

#### Code Refactoring
- Simplified redundant ternary operations for existence checks
- Improved code readability across multiple modules
- Standardized formatting and removed unnecessary blank lines
- Enhanced error messages and logging throughout codebase
- Applied Copilot suggestions for code improvements

#### Version Updates
- Updated SDAF version to 3.17.0.0 across multiple scripts and configuration files
- Consistent version labeling across documentation and scripts

### Breaking Changes

None identified in this release.

### Upgrade Notes

1. **Terraform Provider Properties**: If using custom Terraform modules, update deprecated property names:
   - `enable_rbac_authorization` → `rbac_authorization_enabled`
   - `enable_automatic_updates` → `automatic_updates_enabled`
   - `enable_floating_ip` → `floating_ip_enabled`
   - `protocols_enabled` → `protocol` (for ANF export policies)

2. **Variable Group Updates**: Azure DevOps users should run the new upgrade scripts to migrate variable group configurations:
   - Use `Upgrade-ControlPlaneVariableGroup.ps1` for control plane variables
   - Use `Upgrade-WorkloadZoneVariableGroup.ps1` for workload zone variables

3. **Pipeline Configuration**: Review pipeline configurations if using custom implementations, as variable naming conventions have been updated for consistency

4. **Oracle ASM**: Systems using Oracle ASM should validate ASMLib v3 compatibility and UEK7 support requirements

5. **NVMe Configurations**: Review NVMe configurations on older distributions to ensure compatibility with enhanced udev rules

### Contributors

This release includes contributions from:
- Kimmo Forss (@KimForss)
- Hemanth Damecharla (@hdamecharla)
- Devansh Jain (@devanshjainms)
- Nadeen Noaman (@nnoaman)
- Steffen Bo Thomsen (@SteffenBoThomsen)
- Jesper Severinsen (@jesperseverinsen)
- Csaba Daradics (@daradicscsaba)
- GitHub Copilot (@Copilot)
- dependabot[bot]

---
*This changelog was generated on 2025-06-11.*