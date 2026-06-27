# Release Notes: SDAF 3.20.0.0

## Functional Differences

### 1. App Service support for GitHub Actions
- Added support for deploying to Azure App Service using GitHub Actions in the deployment pipeline.
- Updated deployment scripts and documentation to include steps for configuring GitHub Actions for App Service deployments.

### 2. Enhanched NVME disk support for Azure VMs
- Added support for iSCSI temp disks for Azure Virtual Machines with NVME disks

### 3. Terraform and Infrastructure Changes
- Terraform version references updated from 1.15.1 to 1.15.5
- Removed the NFS sapmnt network perimeter association for Windows systems, as it is not required for Windows deployments
- Fixed the additional IP for HA IPs for Windows deployments

### 4. Miscellaneous fixes
- Do not create a user profile for the 'grid' user on non-ORACLE-ASM deployments
- Oracle HA configuration updates for non ASM deployments


## Notes
