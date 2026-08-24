# Host readiness reference

Companion to `sdaf-readiness-check`. Records what the docs actually say and
does not go further. Every script below is described in
`docs/local/02-00-prepare-execution-environment.md § Readiness verification`;
read that section and each script's own output as the authority.

## check_workstation.sh

- Location: `deploy/scripts/helpers/check_workstation.sh`.
- Documented in: `docs/local/02-00-prepare-execution-environment.md § Readiness
  verification` step 1 (and step 9 of `§ Prepare the host`).
- Prints versions of `az`, `terraform`, `ansible`, `jq`. Non-zero exit or a
  reported missing tool → route to
  `docs/local/troubleshooting.md § Terraform or Azure CLI is not found`.

## Test-SDAFReadiness.ps1

- Location: `deploy/scripts/Test-SDAFReadiness.ps1`.
- Documented in: `docs/local/02-00-prepare-execution-environment.md § Readiness
  verification` step 2.
- Optional diagnostic only when `pwsh` is already available. Do not require or
  install PowerShell to complete the supported Linux readiness path.
- Resolve each item it flags before deploying. Do not narrate behaviour beyond
  the script's own output.

## Test-SDAFURLs.ps1

- Location: `deploy/scripts/Test-SDAFURLs.ps1`.
- Documented in: `docs/local/02-00-prepare-execution-environment.md § Readiness
  verification` step 3.
- Optional diagnostic only when `pwsh` is already available.
- Failure hand-off:
  `docs/local/troubleshooting.md § The execution host cannot reach Key Vault or Storage`.

## Required environment variables

Every SDAF run requires the three variables enumerated in the troubleshooting
guide (`§ A required export is missing`):

- `SAP_AUTOMATION_REPO_PATH`
- `CONFIG_REPO_PATH`
- `ARM_SUBSCRIPTION_ID`

If any is missing, this skill stops and points at that section.