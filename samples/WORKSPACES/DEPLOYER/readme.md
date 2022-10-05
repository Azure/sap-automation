# Deployer samples #

This folder contains a sample deployer configuration.

## MGMT-WEEU-DEP00-INFRASTRUCTURE ##

This configuration deploys a deployer with the following components:


| Component                            | Virtual Machine Name                  | Location        | Details                                                       |
| ------------------------------------ | ------------------------------------- | ----------------| ------------------------------------------------------------- |
| Resource Group                       | MGMT-WEEU-DEP00-INFRASTRUCTURE        | westeurope      |                                                               |
|                                      |                                       |                 |                                                               |
| Virtual Network                      | MGMT-WEEU-DEP00-vnet                  | westeurope      | Address space:     10.170.20.0/24                             |
| Subnet (management)                  | MGMT-WEEU-DEP00_deployment-subnet     | westeurope      | Address space:     10.170.20.64/28                            |
| Subnet (firewall)                    | AzureFirewallSubnet                   | westeurope      | Address space:     10.170.20.0/26                             |
| Subnet (bastion)                     | AzureBastionSubnet                    | westeurope      | Address space:     10.170.20.128/26                           |
| Subnet (webapp)                      | AzureWebappSubnet                     | westeurope      | Address space:     10.170.20.80/28                            |
| Route table                          | MGMT-WEEU-DEP00_route-table           | westeurope      |                                                               |
| Network security group               | MGMT-WEEU-DEP00_deployment-nsg        | westeurope      |                                                               |
|                                      |                                       |                 |                                                               |
| Firewall                             | MGMT-WEEU-DEP00_firewall              | westeurope      |                                                               |
| Firewall public IP                   | MGMT-WEEU-DEP00_firewall-pip          | westeurope      |                                                               |
|                                      |                                       |                 |                                                               |
| Bastion                              | MGMT-WEEU-DEP00_bastion-host          | westeurope      |                                                               |
| Bastion public IP                    | MGMT-WEEU-DEP00_bastion-pip           | westeurope      |                                                               |
|                                      |                                       |                 |                                                               |
| Key Vault                            | MGMTWEEUDEP00user###                  | westeurope      |                                                               |
|                                      |                                       |                 |                                                               |
| Virtual Machine (deployer)           | MGMT-WEEU-DEP00_mgmtweeudep00deploy00 | westeurope      | Standard D4ds v4, Ubuntu 20.04                                |
|                                      |                                       |                 |                                                               |
| Application Service Plan             | mgmt-weeu-app-service-plan###         | westeurope      |                                                               |
| Application Service                  | mgmt-weeu-sapdeployment###            | westeurope      |                                                               |
