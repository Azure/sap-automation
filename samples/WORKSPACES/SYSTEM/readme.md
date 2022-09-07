# System  samples #

This folder contains sample system configurations.

- DEV-WEEU-SAP01-X00
- DEV-WEEU-SAP01-WIN
- QA-WEEU-SAP02-INFRASTRUCTURE
- PRD-WEEU-SAP03-INFRASTRUCTURE

## DEV-WEEU-SAP01-X00 ##

This configuration deploys a system zone with the following components:

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | DEV-WEEU-SAP01-X00                | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database)           | DEV-WEEU-SAP01-X00_x00dhdb00l0### | x00dhdb00l###   | westeurope      | 1     | E16dsv4, SLES 15.3, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs)                | DEV-WEEU-SAP01-X00_x00scs00l###   | x00scs00l###    | westeurope      | 1     | D4sv3, SLES 15.3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | DEV-WEEU-SAP01-X00_x00app00l###   | x00app00l###    | westeurope      | 1     | D4sv3, SLES 15.3, Disks: P10 (sap)             |
| Virtual Machine (app)                | DEV-WEEU-SAP01-X00_x001pp01l###   | x00app01l###    | westeurope      | 1     | D4sv3, SLES 15.3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | DEV-WEEU-SAP01-X00_db-alb         | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | DEV-WEEU-SAP01-X00_scs-alb        | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | DEV-WEEU-SAP01-X00-z1-ppg         | westeurope      |                 |       | One Proximity Placement Group per zone for the deployment |
| Availability set                     | DEV-WEEU-SAP01-X00_z1_app-avset   | westeurope      |                 |       | One Availability set per zone for the deployment |

## DEV-WEEU-SAP01-WIN ##

This configuration deploys a system zone with the following components:

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | DEV-WEEU-SAP01-WIN                | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database)           | DEV-WEEU-SAP01-WIN_windb00w###    | windb00w###     | westeurope      | 1     | E14sv4, Windows Server 2022, Disks: 4 P10 (data), 1 P15 (log) , P6 (sap) |
| Virtual Machine (scs)                | DEV-WEEU-SAP01-WIN_winscs00w###   | x00scs00w###    | westeurope      | 1     | D4sv3, SLES 15.3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | DEV-WEEU-SAP01-WIN_winapp00w###   | winapp00w###    | westeurope      | 1     | D4sv3, SLES 15.3, Disks: P10 (sap)             |
| Virtual Machine (app)                | DEV-WEEU-SAP01-WIN_winapp01w###   | winapp01w###    | westeurope      | 1     | D4sv3, SLES 15.3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | DEV-WEEU-SAP01-WIN_db-alb         | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | DEV-WEEU-SAP01-WIN_scs-alb        | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | DEV-WEEU-SAP01-WIN-z1-ppg         | westeurope      |                 |       | One Proximity Placement Group per zone for the deployment |
| Availability set                     | DEV-WEEU-SAP01-WIN_z1_app-avset   | westeurope      |                 |       | One Availability set per zone for the deployment |
