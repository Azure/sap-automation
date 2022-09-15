# Workload Zone samples #

This folder contains three Workload zone sample configurations.

- DEV-WEEU-SAP01-INFRASTRUCTURE
- QA-WEEU-SAP02-INFRASTRUCTURE
- PRD-WEEU-SAP03-INFRASTRUCTURE

## DEV-WEEU-SAP01-INFRASTRUCTURE ##

This configuration deploys a Workload zone with the following components:

| Component                            | Name                            | Location        | Notes                                          |
| ------------------------------------ | ------------------------------- | --------------- | ---------------------------------------------- |
| Resource Group                       | DEV-WEEU-SAP01-INFRASTRUCTURE   | westeurope      |                                                |
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

## QA-WEEU-SAP02-INFRASTRUCTURE ##

This configuration deploys a Workload zone with the following components:

| Component                            | Name                            | Location        | Notes                                          |
| ------------------------------------ | ------------------------------- | --------------- | ---------------------------------------------- |
| Resource Group                       | QA-WEEU-SAP02-INFRASTRUCTURE    | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Virtual Network                      | QA-WEEU-SAP02-vnet              | westeurope      | Address space:     10.111.0.0/16               |
| Subnet (database)                    | QA-WEEU-SAP02_db-subnet         | westeurope      | Address space:     10.111.96.0/19              |
| Subnet (application)                 | QA-WEEU-SAP02_app-subnet        | westeurope      | Address space:     10.111.32.0/19              |
| Subnet (web)                         | QA-WEEU-SAP02_web-subnet        | westeurope      | Address space:     10.111.128.0/19             |
| Subnet (admin)                       | QA-WEEU-SAP02_admin-subnet      | westeurope      | Address space:     10.111.0.0/19               |
| Route table                          | QA-WEEU-SAP02_route-table       | westeurope      |                                                |
| Network security group (database)    | QA-WEEU-SAP02_dbSubnet-nsg      | westeurope      |                                                |
| Network security group (application) | QA-WEEU-SAP02_appSubnet-nsg     | westeurope      |                                                |
| Network security group (web)         | QA-WEEU-SAP02_webSubnet-nsg     | westeurope      |                                                |
| Network security group (admin)       | QA-WEEU-SAP02_appSubnet-nsg     | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Key Vault                            | QAWEEUSAP02user###              | westeurope      | '###' Is a random identifier                   |
|                                      |                                 |                 |                                                |
| Storage Account                      | qaweeusap02diag###              | westeurope      | Storage account used for Virtual Machine diagnostic logs. '###' Is a random identifier                   |
| Storage Account                      | qaweeusap02witness###           | westeurope      | Cloud witness storage account used for Windows High Availability. '###' Is a random identifier                   |
| Storage Account                      | qaweeusap02install              | westeurope      | NFS Share for installation media. Will be used across all SIDS | |
| Storage Account                      | qaweeusap02transport            | westeurope      | NFS Share for transport. Will be used across all SIDS | |

## PRD-WEEU-SAP03-INFRASTRUCTURE ##

This configuration deploys a Workload zone with the following components:

| Component                            | Name                            | Location        | Notes                                          |
| ------------------------------------ | ------------------------------- | --------------- | ---------------------------------------------- |
| Resource Group                       | PRD-WEEU-SAP03-INFRASTRUCTURE   | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Virtual Network                      | PRD-WEEU-SAP03-vnet             | westeurope      | Address space:     10.112.0.0/16               |
| Subnet (database)                    | PRD-WEEU-SAP03_db-subnet        | westeurope      | Address space:     10.112.96.0/19              |
| Subnet (application)                 | PRD-WEEU-SAP03_app-subnet       | westeurope      | Address space:     10.112.32.0/19              |
| Subnet (web)                         | PRD-WEEU-SAP03_web-subnet       | westeurope      | Address space:     10.112.128.0/19             |
| Subnet (admin)                       | PRD-WEEU-SAP03_admin-subnet     | westeurope      | Address space:     10.112.0.0/19               |
| Subnet (ANF)                         | PRD-WEEU-anf-subnet             | westeurope      | Address space:     10.112.64.0/27              |
| Route table                          | PRD-WEEU-SAP03_route-table      | westeurope      |                                                |
| Network security group (database)    | PRD-WEEU-SAP03_dbSubnet-nsg     | westeurope      |                                                |
| Network security group (application) | PRD-WEEU-SAP03_appSubnet-nsg    | westeurope      |                                                |
| Network security group (web)         | PRD-WEEU-SAP03_webSubnet-nsg    | westeurope      |                                                |
| Network security group (admin)       | PRD-WEEU-SAP03_appSubnet-nsg    | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Key Vault                            | PRDWEEUSAP03user###             | westeurope      | '###' Is a random identifier                   |
|                                      |                                 |                 |                                                |
| Storage Account                      | prdweeusap03diag###             | westeurope      | Storage account used for Virtual Machine diagnostic logs. '###' Is a random identifier                   |
| Storage Account                      | prdweeusap03witness###          | westeurope      | Cloud witness storage account used for Windows High Availability. '###' Is a random identifier                   |
|                                      |                                 |                 |                                                |
| NetApp Account                       | PRD-WEEU-SAP03_netapp_account   | westeurope      |                                                |
| NetApp Capacity Pool                 | PRD-WEEU-SAP03_netapp_pool      | westeurope      |                                                |
| NetApp Volume                        | PRD-WEEU-SAP03_install          | westeurope      | Volume for installation media. Will be used across all SIDS |
| NetApp Volume                        | PRD-WEEU-SAP03_transport        | westeurope      |                                                |
|                                      |                                 |                 |                                                |
| Virtual Machine                      | PRD-WEEU-SAP03_wz-vm00          | westeurope      | Utilisy VM, use it for SAPGUI etc.              |
