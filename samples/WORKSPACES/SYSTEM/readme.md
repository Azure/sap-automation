# System  samples #

This folder contains sample system configurations.

- DEV-WEEU-SAP01-X00
- DEV-WEEU-SAP01-WIN
- QA-WEEU-SAP02-Q00
- QA-WEEU-SAP02-Q01
- QA-WEEU-SAP02-Q02
- PRD-WEEU-SAP03-P00
- PRD-WEEU-SAP03-P01
- PRD-WEEU-SAP03-P02

## DEV-WEEU-SAP01-X00 ##

This configuration deploys a system with the following components:

SID: X00

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | DEV-WEEU-SAP01-X00                | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database)           | DEV-WEEU-SAP01-X00_x00dhdb00l0### | x00dhdb00l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs)                | DEV-WEEU-SAP01-X00_x00scs00l###   | x00scs00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | DEV-WEEU-SAP01-X00_x00app00l###   | x00app00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | DEV-WEEU-SAP01-X00_x001pp01l###   | x00app01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | DEV-WEEU-SAP01-X00_db-alb         | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | DEV-WEEU-SAP01-X00_scs-alb        | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | DEV-WEEU-SAP01-X00-z1-ppg         | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | DEV-WEEU-SAP01-X00_z1_app-avset   | westeurope      |                 |       | One Availability set per zone                  |

## DEV-WEEU-SAP01-WIN ##

This configuration deploys a Windows system zone with the following components:

SID: WIN

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | DEV-WEEU-SAP01-WIN                | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database)           | DEV-WEEU-SAP01-WIN_windb00w###    | windb00w###     | westeurope      | 1     | E14sv4, Windows Server 2022, Disks: 4 P10 (data), 1 P15 (log) , P6 (sap) |
| Virtual Machine (scs)                | DEV-WEEU-SAP01-WIN_winscs00w###   | x00scs00w###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | DEV-WEEU-SAP01-WIN_winapp00w###   | winapp00w###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | DEV-WEEU-SAP01-WIN_winapp01w###   | winapp01w###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | DEV-WEEU-SAP01-WIN_db-alb         | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | DEV-WEEU-SAP01-WIN_scs-alb        | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | DEV-WEEU-SAP01-WIN-z1-ppg         | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | DEV-WEEU-SAP01-WIN_z1_app-avset   | westeurope      |                 |       | One Availability set per zone                  |

## QA-WEEU-SAP02-Q00 ##

This configuration deploys a Redhat 8.4 system using Azure Files NFS for shared files with the following components:

SID: Q00

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | QA-WEEU-SAP02-Q00                 | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database)           | QA-WEEU-SAP02-Q00_q00dhdb00l###   | q00dhdb00l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs)                | QA-WEEU-SAP02-Q00_q00scs00l###    | q00scs00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | QA-WEEU-SAP02-Q00_q00app00l###    | q00app00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | QA-WEEU-SAP02-Q00_q001pp01l###    | q00app01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | QA-WEEU-SAP02-Q00_db-alb          | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | QA-WEEU-SAP02-Q00_scs-alb         | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | QA-WEEU-SAP02-Q00-z1-ppg          | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | QA-WEEU-SAP02-Q00_z1_app-avset    | westeurope      |                 |       | One Availability set per zone                  |
|                                      |                                   |                 |                 |       |                                                |
| Storage Account                      | qaweeusap02q00sapmnt              | westeurope      |                 |       | Storage account used for sapmnt share          |

## QA-WEEU-SAP02-Q01 ##

This configuration deploys a highly available Redhat 8.4 system using Azure Files NFS for shared files with the following components:

SID: Q01

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | QA-WEEU-SAP02-Q00                 | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database, primary)  | QA-WEEU-SAP02-Q01_q01dhdb00l###   | q01dhdb00l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (database,secondary) | QA-WEEU-SAP02-Q01_q01dhdb01l###   | q01dhdb01l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs, ASCS)          | QA-WEEU-SAP02-Q01_q01scs00l###    | q01scs00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (scs, ERS)           | QA-WEEU-SAP02-Q01_q01scs01l###    | q01scs01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | QA-WEEU-SAP02-Q01_q01app00l###    | q01app00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | QA-WEEU-SAP02-Q01_q001pp01l###    | q01app01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | QA-WEEU-SAP02-Q01_db-alb          | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | QA-WEEU-SAP02-Q01_scs-alb         | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | QA-WEEU-SAP02-Q01-z1-ppg          | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | QA-WEEU-SAP02-Q01_z1_app-avset    | westeurope      |                 |       | One Availability set per zone                  |
|                                      |                                   |                 |                 |       |                                                |
| Storage Account                      | qaweeusap02q00sapmnt              | westeurope      |                 |       | Storage account used for sapmnt share          |

## QA-WEEU-SAP02-Q02 ##

This configuration deploys a highly available SUSE 15 SP 3 system using Azure Files NFS for shared files with the following components:

SID: Q02

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | QA-WEEU-SAP02-Q00                 | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database, primary)  | QA-WEEU-SAP02-Q02_q02dhdb00l###   | q02dhdb00l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (database,secondary) | QA-WEEU-SAP02-Q02_q02dhdb01l###   | q02dhdb01l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs, ASCS)          | QA-WEEU-SAP02-Q02_q02scs00l###    | q02scs00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (scs, ERS)           | QA-WEEU-SAP02-Q02_q02scs01l###    | q02scs01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | QA-WEEU-SAP02-Q02_q02app00l###    | q02app00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | QA-WEEU-SAP02-Q01_q001pp01l###    | q02app01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | QA-WEEU-SAP02-Q01_db-alb          | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | QA-WEEU-SAP02-Q01_scs-alb         | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | QA-WEEU-SAP02-Q01-z1-ppg          | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | QA-WEEU-SAP02-Q01_z1_app-avset    | westeurope      |                 |       | One Availability set per zone                  |
|                                      |                                   |                 |                 |       |                                                |
| Storage Account                      | qaweeusap02q00sapmnt              | westeurope      |                 |       | Storage account used for sapmnt share          |

## PRD-WEEU-SAP03-P00 ##

This configuration deploys a Redhat 8.4 system using Azure NetApp Files for shared files with the following components:

SID: P00

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | PRD-WEEU-SAP03-P00                | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database)           | PRD-WEEU-SAP03-P00_p00dhdb00l###  | p00dhdb00l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs)                | PRD-WEEU-SAP03-P00_p00scs00l###   | p00scs00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | PRD-WEEU-SAP03-P00_p00app00l###   | p00app00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | PRD-WEEU-SAP03-P00_p001pp01l###   | p00app01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | PRD-WEEU-SAP03-P00_db-alb         | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | PRD-WEEU-SAP03-P00_scs-alb        | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | PRD-WEEU-SAP03-P00-z1-ppg         | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | PRD-WEEU-SAP03-P00_z1_app-avset   | westeurope      |                 |       | One Availability set per zone                  |

## PRD-WEEU-SAP03-P01 ##

This configuration deploys a highly available SUSE 15 SP3  system using Azure NetApp Files for shared files with the following components:

SID: P01

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | PRD-WEEU-SAP03-P00                | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database, primary)  | PRD-WEEU-SAP03-P01_p01dhdb00l###  | p01dhdb00l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (database,secondary) | PRD-WEEU-SAP03-P01_p01dhdb01l###  | p01dhdb01l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs, ASCS)          | PRD-WEEU-SAP03-P01_p01scs00l###   | p01scs00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (scs, ERS)           | PRD-WEEU-SAP03-P01_p01scs01l###   | p01scs01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | PRD-WEEU-SAP03-P01_p01app00l###   | p01app00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | PRD-WEEU-SAP03-P01_p001pp01l###   | p01app01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | PRD-WEEU-SAP03-P01_db-alb         | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | PRD-WEEU-SAP03-P01_scs-alb        | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | PRD-WEEU-SAP03-P01-z1-ppg         | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | PRD-WEEU-SAP03-P01_z1_app-avset   | westeurope      |                 |       | One Availability set per zone                  |

## PRD-WEEU-SAP03-P02 ##

This configuration deploys a highly available Red Hat 8.2 system using Azure NetApp files for shared files with the following components:

HANA Data and HANA log volumes are on Azure NetApp Files (ANF).
SID: P02

| Component                            | Virtual Machine Name              | Hostname        | Location        | Count | Details                                        |
| ------------------------------------ | --------------------------------- | ----------------| --------------- | ----- | ---------------------------------------------- |
| Resource Group                       | PRD-WEEU-SAP03-P00                | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Virtual Machine (database, primary)  | PRD-WEEU-SAP03-P02_q02dhdb00l###  | p02dhdb00l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (database,secondary) | PRD-WEEU-SAP03-P02_q02dhdb01l###  | p02dhdb01l###   | westeurope      | 1     | E20dsv4, Disks: 4 P10 (data), 3 P6 (log) , P15 (sap), P20 (backup), P20 (shared) |
| Virtual Machine (scs, ASCS)          | PRD-WEEU-SAP03-P02_q02scs00l###   | p02scs00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (scs, ERS)           | PRD-WEEU-SAP03-P02_q02scs01l###   | p02scs01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (primary app)        | PRD-WEEU-SAP03-P02_q02app00l###   | p02app00l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
| Virtual Machine (app)                | PRD-WEEU-SAP03-P01_q001pp01l###   | p02app01l###    | westeurope      | 1     | D4sv3, Disks: P10 (sap)             |
|                                      |                                   |                 |                 |       |                                                |
| Load Balancer (database)             | PRD-WEEU-SAP03-P01_db-alb         | westeurope      |                 |       |                                                |
| Load Balancer (scs)                  | PRD-WEEU-SAP03-P01_scs-alb        | westeurope      |                 |       |                                                |
|                                      |                                   |                 |                 |       |                                                |
| Proximity Placement Group            | PRD-WEEU-SAP03-P01-z1-ppg         | westeurope      |                 |       | One Proximity Placement Group per zone         |
| Availability set                     | PRD-WEEU-SAP03-P01_z1_app-avset    | westeurope      |                 |       | One Availability set per zone                  |
