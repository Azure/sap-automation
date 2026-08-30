---
name: sdaf-sovereign-cloud
description: >
  Explain the current SDAF sovereign-cloud deltas without inventing a generic
  "all sovereigns" runbook. Focus on Azure Government only: the GitHub Actions
  cloud values `ARM_ENVIRONMENT=usgovernment`,
  `AZURE_ENVIRONMENT=AzureUSGovernment`, and
  `AZURE_AUDIENCE=api://AzureADTokenExchangeUSGov`; the Government
  `dns_zone_names` block; `USAR` / `USTE` / `USVI`; the 3.22+ image boundary;
  and the documented Government login, client-secret, SKU, and
  private-endpoint failure signatures. Use when a user says "Azure
  Government", "sovereign cloud", "ARM_ENVIRONMENT", "AZURE_AUDIENCE",
  "AADSTS900382", "USVI", or "Government DNS zones". Do NOT use for generic
  stage execution or to infer Azure China / German procedures from
  cloud-name literals alone.
allowed-tools: shell
license: MIT
---

# SDAF Sovereign Cloud

Context-primer. Explains the currently sourced sovereign-cloud deltas for SDAF
without promising parity across every surface or Azure cloud. The operator path
in scope is Azure Government. For exact anchors, commands, and ownership
boundaries, see
[`references/documented-cloud-boundaries.md`](references/documented-cloud-boundaries.md).

## When to invoke

Trigger on: "Azure Government", "sovereign cloud", "ARM_ENVIRONMENT",
"AZURE_AUDIENCE", "AADSTS900382", "USVI", "Government dns_zone_names", "wrong
azure/login cloud", "Government VM size not available".

Do NOT trigger on: generic control-plane/workload-zone/SAP-system deployment,
a general private-endpoint policy design decision, or unsupported-cloud
enablement.

## Scope boundary

Teach only Azure Government deltas that current SDAF docs or code explicitly
name.

- `CHANGELOG/v3.22.0.0` is the first release note in this repo that explicitly
  names Azure Government support in the GitHub Actions setup flow and adds
  `USAR`, `USTE`, and `USVI`.
- The GitHub setup utility defines sovereign OIDC values only for
  `AzureUSGovernment` and rejects unknown clouds.
- Local shell code also maps `AzureChinaCloud` and `AzureGermanCloud`, but
  that alone is not an end-to-end operator runbook.

If the operator asks for China, German, or another sovereign path, say the
current sources in scope do not publish that runbook and stop.

## Cloud values that must move together

For the GitHub Actions surface, set these together:

- `ARM_ENVIRONMENT = usgovernment`
- `AZURE_ENVIRONMENT = AzureUSGovernment`
- `AZURE_AUDIENCE = api://AzureADTokenExchangeUSGov`

Workflow `00` copies these values to the control-plane environment; workflow
`02` propagates them to workload environments.

Do not set only one or two of them:

- `AZURE_ENVIRONMENT` and `AZURE_AUDIENCE` steer `azure/login`.
- `ARM_ENVIRONMENT` steers the `azurerm` provider.
- If Terraform later fails with `AADSTS900382`, first check that every
  Terraform step is exporting `ARM_ENVIRONMENT` with the ARM credentials.

## Region and configuration boundaries

Government region codes are documented in `docs/region-codes.md`:

- `usgovarizona` → `USAR`
- `usgovtexas` → `USTE`
- `usgovvirginia` → `USVI`

If a GitHub control-plane run shows `Invalid index` with an empty `Region:`,
treat the pinned `DOCKER_IMAGE` as the first boundary check. The documented
image gate for Government region codes is SDAF `3.22+`.

For Azure Government generated `WORKSPACES` files, uncomment the Government
`dns_zone_names` block. For Public Azure, leave it commented. Do not enable
multiple DNS blocks.

For an Azure Government workload-zone deployment that fails with
`PrivateEndpointCannotBeCreatedInSubnetThatHasNetworkPoliciesEnabled`, set:

```terraform
private_endpoint_network_policies = "Disabled"
```

Do not generalize that workaround to other clouds. If the operator needs the
broader workload-zone/network-policy decision, hand off to
`sdaf-workload-zone`.

## Common documented Azure Government failure signatures

- `AADSTS900382` during Terraform init/apply: Terraform is still targeting the
  wrong cloud endpoint. Check `ARM_ENVIRONMENT` first.
- `azure/login` succeeds against the wrong cloud: the workflow is missing
  `AZURE_ENVIRONMENT` and/or `AZURE_AUDIENCE`.
- `AADSTS7000215` or `AADSTS700016`: Terraform is not using the workflow's
  OIDC token. When `USE_MSI=false`, `ARM_CLIENT_SECRET` must exist and be
  valid in the running environment.
- `SkuNotAvailable`: query the subscription's offered sizes in the target
  region and set the stage-specific size variable; for the control plane, that
  variable is `deployer_size`.

## Hand-off

- GitHub Actions bootstrap or workflow mechanics: use the GitHub surface plugin
  or the referenced GitHub bootstrap docs.
- Local control-plane execution: `sdaf-control-plane-bootstrap`.
- Workload-zone execution or the broader network-policy choice:
  `sdaf-workload-zone`.
- SAP-system deployment: `sdaf-sap-system`.
- Symptoms outside the documented Government cases above:
  `sdaf-failure-triage`.

## Hard rules

- Do not infer an end-to-end China or German runbook from cloud-name literals
  alone.
- Do not apply Azure Government `dns_zone_names` or subnet-policy settings to
  Public Azure by default.
- Do not treat `ARM_ENVIRONMENT` as sufficient for `azure/login`, or
  `AZURE_ENVIRONMENT` / `AZURE_AUDIENCE` as sufficient for Terraform.
- Do not claim Local/ADO/GitHub sovereign-cloud parity unless the cited source
  for that surface says so.
- If the question depends on an uncited cloud, surface, or workaround, say the
  current sources are silent and stop.
