# Azure region codes

SAP Deployment Automation Framework (SDAF) shortens every Azure region name to
a four-character region code. The code appears in resource names, resource
group names, Terraform state file names, and the names of the generated
configuration files and directories under `WORKSPACES`.

Use this page to look up the code for a region, to confirm which regions the
name generator has a code for, and to add a region that is not listed. A region
appearing in this table only means SDAF can derive a name code for it; it
doesn't establish that the region is supported. See the
[supportability matrix](https://learn.microsoft.com/azure/sap/automation/supportability)
for support statements.

## Where the region code appears

The name generator derives the code from the deployment location and exposes
it as `location_short`:

```hcl
location_short = upper(try(var.region_mapping[var.location], "unkn"))
```

Source:
[`deploy/terraform/terraform-units/modules/sap_namegenerator/variables_local.tf`](../deploy/terraform/terraform-units/modules/sap_namegenerator/variables_local.tf)

`location_short` then forms the second segment of the SDAF naming convention:

| Deployment | Pattern | Example in `westeurope` |
| --- | --- | --- |
| Control plane | `<ENV>-<CODE>-<DEPLOYER>-INFRASTRUCTURE` | `MGMT-WEEU-DEP01-INFRASTRUCTURE` |
| SAP library | `<ENV>-<CODE>-SAP_LIBRARY` | `MGMT-WEEU-SAP_LIBRARY` |
| Workload zone | `<ENV>-<CODE>-<VNET>-INFRASTRUCTURE` | `DEV-WEEU-SAP01-INFRASTRUCTURE` |
| SAP system | `<ENV>-<CODE>-<VNET>-<SID>` | `DEV-WEEU-SAP01-X00` |

Because the code is part of the resource group name and the Terraform state
file name, it is fixed for the lifetime of a deployment. Changing the region of
an existing deployment changes the code, and therefore renames every resource.

## Unmapped regions fall back to `unkn`

The lookup uses `try(..., "unkn")`. A region that is not in the map does not
fail the deployment. It produces the literal code `UNKN`, so a deployment in an
unmapped region succeeds with names such as `MGMT-UNKN-DEP01-INFRASTRUCTURE`.

Two deployments in two different unmapped regions therefore generate the same
names and collide. Confirm that your region appears in the table below before
you deploy.

## Supported regions

| Azure region | Region code |
| --- | --- |
| `australiacentral` | `AUCE` |
| `australiacentral2` | `AUC2` |
| `australiaeast` | `AUEA` |
| `australiasoutheast` | `AUSE` |
| `brazilsouth` | `BRSO` |
| `brazilsoutheast` | `BRSE` |
| `brazilus` | `BRUS` |
| `canadacentral` | `CACE` |
| `canadaeast` | `CAEA` |
| `centralindia` | `CEIN` |
| `centralus` | `CEUS` |
| `centraluseuap` | `CEUA` |
| `chilecentral` | `CHCE` |
| `denmarkeast` | `DEEA` |
| `eastasia` | `EAAS` |
| `eastus` | `EAUS` |
| `eastus2` | `EUS2` |
| `eastus2euap` | `EUSA` |
| `eastusstg` | `EUSG` |
| `francecentral` | `FRCE` |
| `francesouth` | `FRSO` |
| `germanynorth` | `GENO` |
| `germanywest` | `GEWE` |
| `germanywestcentral` | `GEWC` |
| `indonesiacentral` | `INCE` |
| `israelcentral` | `ISCE` |
| `italynorth` | `ITNO` |
| `japaneast` | `JAEA` |
| `japanwest` | `JAWE` |
| `jioindiacentral` | `JINC` |
| `jioindiawest` | `JINW` |
| `koreacentral` | `KOCE` |
| `koreasouth` | `KOSO` |
| `malaysiawest` | `MAWE` |
| `mexicocentral` | `MECE` |
| `newzealandnorth` | `NZNO` |
| `northcentralus` | `NCUS` |
| `northeurope` | `NOEU` |
| `norwayeast` | `NOEA` |
| `norwaywest` | `NOWE` |
| `polandcentral` | `PLCE` |
| `qatarcentral` | `QACE` |
| `southafricanorth` | `SANO` |
| `southafricawest` | `SAWE` |
| `southcentralus` | `SCUS` |
| `southcentralusstg` | `SCUG` |
| `southeastasia` | `SOEA` |
| `southindia` | `SOIN` |
| `spaincentral` | `SPCE` |
| `swedencentral` | `SECE` |
| `swedensouth` | `SESO` |
| `switzerlandnorth` | `SWNO` |
| `switzerlandwest` | `SWWE` |
| `uaecentral` | `UACE` |
| `uaenorth` | `UANO` |
| `uksouth` | `UKSO` |
| `ukwest` | `UKWE` |
| `usgovarizona` | `USAR` |
| `usgovtexas` | `USTE` |
| `usgovvirginia` | `USVI` |
| `westcentralus` | `WCUS` |
| `westeurope` | `WEEU` |
| `westindia` | `WEIN` |
| `westus` | `WEUS` |
| `westus2` | `WUS2` |
| `westus3` | `WUS3` |

## Add a region

The mapping is implemented independently in six files. A region is only fully
supported when it is present in all of them, because different stages of a
deployment read different files.

| File | Direction |
| --- | --- |
| [`deploy/terraform/terraform-units/modules/sap_namegenerator/variables_global.tf`](../deploy/terraform/terraform-units/modules/sap_namegenerator/variables_global.tf) | Region name to code |
| [`deploy/scripts/deploy_utils.sh`](../deploy/scripts/deploy_utils.sh) | Region name to code |
| [`deploy/scripts/pipeline_scripts/helper.sh`](../deploy/scripts/pipeline_scripts/helper.sh) | Code to region name |
| [`deploy/scripts/pipeline_scripts/v2/shared_functions.sh`](../deploy/scripts/pipeline_scripts/v2/shared_functions.sh) | Code to region name |
| [`deploy/scripts/pipeline_scripts/v2/shared_functions_v2.sh`](../deploy/scripts/pipeline_scripts/v2/shared_functions_v2.sh) | Code to region name |
| [`deploy/scripts/pipeline_scripts/22-sample-deployer-configuration.ps1`](../deploy/scripts/pipeline_scripts/22-sample-deployer-configuration.ps1) | Code to region name |

To add a region:

1. Choose a four-character code that is not already used in the table above.
   Codes are conventionally the first two letters of the geography followed by
   the first two letters of the region, for example `westeurope` becomes
   `WEEU`.
2. Add the region to all six files. Keep each list in alphabetical order by
   region name.
3. Add the region to the table on this page.
4. Confirm that the code is still unique across the whole table.

Use uppercase in the shell and PowerShell files and lowercase in
`variables_global.tf`. The name generator applies `upper()` to the value it
reads, and the shell lookups compare against uppercase codes.

## Related

- [SDAF architecture](architecture.md) describes the deployment layers that
  consume these names.
- [Documentation conventions](documentation-conventions.md) describes how to
  validate a change to this page against the source files.
