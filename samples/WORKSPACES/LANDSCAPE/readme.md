# Workload Zone samples #

This folder contains three Workload zone sample configurations.

- DEV-WEEU-SAP01-INFRASTRUCTURE
- QA-WEEU-SAP02-INFRASTRUCTURE
- PRD-WEEU-SAP03-INFRASTRUCTURE

## DEV-WEEU-SAP01-INFRASTRUCTURE ##

This configuration deploys a Workload zone with the following components:

| Component                            | Name                            | Location        | Notes                                          |
| ------------------------------------ | ------------------------------- | --------------- | ---------------------------------------------- |
| Resource Group                       | MGMT-WEEU-DEP00-INFRASTRUCTURE  | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Virtual Network                      | DEV-WEEU-SAP01-vnet             | westeurope      | Address space:     10.110.0.0/16               |
| Subnet (database)                    | DEV-WEEU-SAP01_db-subnet        | westeurope      | Address space:     10.110.96.0/19              |
| Subnet (application)                 | DEV-WEEU-SAP01_app-subnet       | westeurope      | Address space:     10.110.32.0/19              |
| Subnet (web)                         | DEV-WEEU-SAP01_web-subnet       | westeurope      | Address space:     10.110.128.0/19             |
| Subnet (admin)                       | DEV-WEEU-SAP01_admin-subnet     | westeurope      | Address space:     10.110.0.0/19               |
| Route table                          | DEV-WEEU-SAP01_route-table      | westeurope      |                                                |
| Network security group (database)    | DEV-WEEU-SAP01_dbSubnet-nsg     | westeurope      |                                                |
| Network security group (application) | DEV-WEEU-SAP01_appSubnet-nsg    | westeurope      |                                                |
| Network security group (web)         | DEV-WEEU-SAP01_webSubnet-nsg    | westeurope      |                                                |
| Network security group (admin)       | DEV-WEEU-SAP01_appSubnet-nsg    | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Key Vault                            | DEVWEEUSAP01user###             | westeurope      | '###' Is a random identifier                   |
|                                      |                                 |                 |                                                |
| Storage Account                      | devweeusap01diag###             | westeurope      | Storage account used for Virtual Machine diagnostic logs. '###' Is a random identifier                   |
| Storage Account                      | devweeusap01witness###          | westeurope      | Cloud witness storage account used for Windows High Availability. '###' Is a random identifier                   |
