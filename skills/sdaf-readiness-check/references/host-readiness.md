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
- Doc says: reports readiness of the execution host for an SDAF deployment;
  each item it flags must be resolved before deploying. For flags, run
  `Get-Help ...\Test-SDAFReadiness.ps1 -Full` — do not narrate behaviour
  beyond what `Get-Help` or the script's own output shows.

## Test-SDAFURLs.ps1

- Location: `deploy/scripts/Test-SDAFURLs.ps1`.
- Documented in: `docs/local/02-00-prepare-execution-environment.md § Readiness
  verification` step 3.
- Doc says: reports whether the endpoints SDAF contacts at deploy time are
  reachable from this host. Failure hand-off:
  `docs/local/troubleshooting.md § The execution host cannot reach Key Vault or Storage`.
- For flags, use `Get-Help`.

## validate.sh

- Location: `deploy/scripts/validate.sh`.
- Documented in: `docs/local/02-00-prepare-execution-environment.md § Readiness
  verification` step 4.
- Doc says: inspects a workspace `.tfvars` file's presence and expected
  fields; non-zero exit or printed error means the file is not ready.
- Invocation constraint: run from the directory containing the tfvars, pass
  the basename only — see
  `docs/local/troubleshooting.md § A parameter file is not found`.

## Required environment variables

Every SDAF run requires the three variables enumerated in the troubleshooting
guide (`§ A required export is missing`):

- `SAP_AUTOMATION_REPO_PATH`
- `CONFIG_REPO_PATH`
- `ARM_SUBSCRIPTION_ID`

If any is missing, this skill stops and points at that section.