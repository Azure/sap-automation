# Quality-assurance operator reference

## Available surfaces

- **Local:** use `docs/local/07-10-quality-assurance.md`.
- **Azure DevOps:** use the documented pipeline 13 path only when it exists in
  the operator's project.
- **GitHub Actions:** the current operator documentation marks the wrapper as
  pending; do not invent a workflow.

## Test modes

| Intent | Test type | Functional type | Offline |
| --- | --- | --- | --- |
| Configuration checks | `ConfigurationChecks` | n/a | `false` |
| Database HA | `SAPFunctionalTests` | `DatabaseHighAvailability` | `false` |
| Central-services HA | `SAPFunctionalTests` | `CentralServicesHighAvailability` | `false` |
| Azure Backup database | `SAPFunctionalTests` | `AzureBackupDatabase` | `false` |
| Database HA evidence review | `SAPFunctionalTests` | `DatabaseHighAvailability` | `true` |
| Central-services HA evidence review | `SAPFunctionalTests` | `CentralServicesHighAvailability` | `true` |

## Operator safeguards

- Configuration validation does not install SAP.
- HA functional tests are disruptive and require an approved maintenance window.
- `TEST_CASES` must be scoped by the matching test group.
- An empty match or `No test results found.` is not success.
- Retain the generated logs, reports, and selected-case evidence.

Sources: `docs/local/07-10-quality-assurance.md`,
`docs/supportability.md`, and `docs/deployment-options.md`.
