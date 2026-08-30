# Documented sovereign-cloud boundaries

The current operator guidance covers Azure Government only.

## Values that move together

- `ARM_ENVIRONMENT=usgovernment`
- `AZURE_ENVIRONMENT=AzureUSGovernment`
- `AZURE_AUDIENCE=api://AzureADTokenExchangeUSGov`

## Documented region codes

- `usgovarizona` → `USAR`
- `usgovtexas` → `USTE`
- `usgovvirginia` → `USVI`

## Operator checks

- Use an SDAF image/version that includes Azure Government support.
- Apply the documented Government DNS-zone block only to Government workspaces.
- Apply the private-endpoint policy workaround only for the documented Azure
  Government error.
- For `SkuNotAvailable`, list sizes offered in the target subscription and region.
- For OIDC failures, confirm cloud, audience, environment, and subject settings
  from the GitHub Actions operator documentation.

China, German, and other sovereign-cloud procedures remain out of scope until
published operator documentation exists.
