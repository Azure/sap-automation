# SAP Library samples #

This folder contains a SAP Library configuration sample

## MGMT-WEEU-SAP_LIBRARY ##

This configuration deploys a Workload zone with the following components:

| Component                            | Name                            | Location        | Notes                                          |
| ------------------------------------ | ------------------------------- | --------------- | ---------------------------------------------- |
| Resource Group                       | MGMT-WEEU-SAP_LIBRARY           | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Storage Account                      | mgmtweeusaplib###               | westeurope      | Storage account used SAP installation media. '###' Is a random identifier                   |
| Storage Account                      | mgmtweeutfstate###              | westeurope      | Storage account used Terraform state file. '###' Is a random identifier                   |
|                                      |                                 |                 |                                                |
| DNS                                  | sap.contoso.net                 | westeurope      |                                                |
