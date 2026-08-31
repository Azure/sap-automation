# SAP installation stage map

Use this map to select the smallest documented installation stage.

| Intent | Local selection | Azure DevOps selection |
| --- | --- | --- |
| Validate inputs | Validate parameters | Validation stage |
| Configure base OS | Core Operating System Configuration | Base OS configuration |
| Configure SAP OS | SAP Operating System Configuration | SAP OS configuration |
| Prepare reviewed media on hosts | Local software download | BOM processing |
| Install central services | SCS Installation & High Availability Configuration | SCS installation |
| Install database | Database installation | Database install |
| Load database | Database Load | Database load |
| Configure database HA | Database High Availability Configuration | HA configuration |
| Install PAS | Primary Application Server installation | PAS installation |
| Install additional app servers | Application Server installations | Application-server installation |
| Install Web Dispatcher | Web Dispatcher installations | Web Dispatcher installation |

## Recovery guidance

- Always validate parameters first.
- Preserve the first failed stage, host, exit code, and logs.
- Review the documented completion marker for the selected stage.
- Correct the failed prerequisite, then rerun only the smallest applicable stage.
- Do not use every stage as the default retry.
- Remove temporary private-key material after local execution.

Sources: `docs/local/06-00-software-and-installation.md` and the documented
Azure DevOps installation guide.
