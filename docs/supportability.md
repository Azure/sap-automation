# SAP Deployment Automation Framework supportability

This article summarizes the validated technical scope for SAP Deployment
Automation Framework (SDAF). Use it with current SAP product documentation,
SAP on Azure certification guidance, Azure service availability, and the
release notes for the SDAF version that you deploy.

> [!IMPORTANT]
> Technical supportability isn't a support entitlement. This page
> doesn't replace Microsoft support policy, SAP Product Availability Matrix
> requirements, or SAP Notes.

## Interpret the matrix

The following terms apply:

- **Supported** means the published SDAF technical scope includes the platform
  or capability.
- **Tested** means the version appears in the published SDAF test matrix.
- **Limited** means only identified scenarios are included.
- **Organization-managed extension** means SDAF exposes an input or hook, but
  the adopting organization owns validation and maintenance of the resulting
  customization.

Availability in Terraform, Ansible, or a sample doesn't establish support by
itself. The matrices in this article record the July 2026 documentation
baseline. Code can include enablement for versions or scenarios that aren't
yet part of the published tested baseline.

## Execution-host boundary

The control-plane deployer must run Linux because it acts as the Ansible
controller. The infrastructure deployed by SDAF can include supported Linux
and Windows workloads on x86-64 or x64 hardware.

Don't use the deployed-workload operating-system matrix as an execution-host
matrix. Host preparation scripts, hosted runners, and self-hosted agents have
their own prerequisites.

## Operating systems

| Family | Published framework scope | Published tested versions |
| --- | --- | --- |
| Red Hat Enterprise Linux | 64-bit x86-64, 7.x through 10.0 | 7.9, 8.2, 8.4, 8.6, 8.8, 9.0, 9.2, 9.4, 9.6, 10.0 |
| SUSE Linux Enterprise Server | 64-bit x86-64, 12.x and 15.x | 12 SP4, 15 SP2, 15 SP3, 15 SP4, 15 SP5, 15 SP6, 15 SP7 |
| Oracle Linux | 64-bit x86-64 | 8.2, 8.4, 8.6, 8.8, 8.9 |
| Windows Server | 64-bit x64 | 2016, 2019, 2022 |

An operating-system version must also be supported for the selected SAP
product, database, Azure VM family, storage design, and high-availability
implementation.

## Database back ends

The current published SDAF matrix lists these database back ends and versions:

| Database | Published versions |
| --- | --- |
| SAP HANA for S/4HANA or NetWeaver | 1909, 2020, 2021, 2022, 2023, 2025 |
| SAP ASE | 1603SP11, 1603SP14 |
| IBM Db2 | 11.5 |
| Oracle Database | 19.0 |
| Microsoft SQL Server | 2016, 2019, 2022 |

Confirm the exact SAP application and database combination in the SAP Product
Availability Matrix. A version listed here doesn't make every cross-product
combination valid.

Use the
[`BOM`](https://github.com/Azure/SAP-automation-samples/tree/main/BOM)
directory to locate the software manifests currently available in the samples
repository. The presence of a BOM doesn't independently establish support for
an operating-system, database, or SAP product combination.

## Storage

| Storage option | Scope |
| --- | --- |
| Azure Premium SSD | Supported where the selected SAP workload and VM SKU permit it |
| Azure Premium SSD v2 | Supported where regional, VM, and workload requirements permit it |
| Azure Ultra Disk | Limited to eligible scenarios, such as qualifying SAP HANA log volumes |
| Azure NetApp Files | Supported for applicable shared and database file systems; application volume group support is available for SAP HANA scenarios |
| Azure Files NFS | Supported for shared file systems, not database files |

SDAF also exposes Azure Disk Encryption and organization-managed-key options.
Validate encryption compatibility with the selected disk, image, region, and
deployment topology.

## SAP application topologies

| Topology | Description |
| --- | --- |
| Standalone | Database and SAP application roles run on one server |
| Distributed | Database and application tiers are separated; central services and application servers can also be separated |

### Database topologies

The published support topology describes a distributed high-availability
deployment. SDAF implements that database tier through separate scale-up and
SAP HANA scale-out paths. The following rows describe those implementation
paths; they don't independently establish support for a specific product,
operating-system, or infrastructure combination.

| Availability model | Topology | Framework path | Configuration |
| --- | --- | --- | --- |
| Non-HA | Database non-HA | The database tier doesn't use a high-availability configuration | `database_high_availability = false` and `database_server_count >= 1` |
| High availability | Scale-up | The database tier uses the database-specific clustered high-availability path | `database_high_availability = true`, `database_server_count = 1` and `database_HANA_use_scaleout_scenario = false` |
| High availability | Scale-out | The SAP HANA database tier uses the scale-out clustered high-availability path | `database_high_availability = true`, `database_server_count > 1` and `database_HANA_use_scaleout_scenario = true` |

Database HA requires `database_high_availability = true`. For SAP HANA HA,
`database_HANA_use_scaleout_scenario` selects the implementation path:
`false` uses scale-up and `true` uses scale-out. These inputs are defined in
[`tfvar_variables.tf`](../deploy/terraform/run/sap_system/tfvar_variables.tf);
the corresponding roles are selected in
[`playbook_04_00_01_db_ha.yaml`](../deploy/ansible/playbook_04_00_01_db_ha.yaml).
Scale-out-specific inputs also expose standby-node and observer configuration.
Validate the node count, storage design, standby roles, and selected HA
implementation for the adopted release.

### SAP central services topologies

| Topology | Description | Configuration |
| --- | --- | --- |
| Single central services instance | One SAP central services server is deployed without an enqueue replication server cluster | `scs_server_count = 1` and `scs_high_availability = false` |
| Highly available central services | Each configured central-services unit deploys an SAP central services and enqueue replication server pair | `scs_server_count = 1` and `scs_high_availability = true` |

`scs_server_count = 0` omits the central-services tier. When high availability
is enabled, SDAF creates two virtual machines for each configured
central-services unit.

High availability depends on operating-system, database, fencing, load
balancer, availability-zone or availability-set, and storage compatibility.
Review the complete design rather than treating the topology row as an
independent approval.

## Deployment topologies

SDAF supports:

- **Green-field deployment**, where Terraform creates the required resources.
- **Brown-field deployment**, where supported existing Azure resources are
  referenced through documented resource-ID inputs.

Brown-field support is resource-specific. Confirm that the applicable root
module accepts an existing resource ID and that its validation, permissions,
networking, and lifecycle behavior match the intended design.

## Azure capabilities

The published supportability scope includes the following capability groups:

| Area | Included capabilities |
| --- | --- |
| Compute | Azure virtual machines, custom images, accelerated networking, authentication choices, SKU configuration, anchor VMs, and new or existing proximity placement groups |
| Networking | Organization-provided or Azure-provided addressing, new or existing virtual networks, subnets, network security groups, peering, private endpoints, and application security groups |
| Availability | Availability zones and supported highly available configurations |
| Traffic and perimeter | Standard Azure Load Balancer and Azure Firewall integration |
| Storage | Boot diagnostics, SAP installation media, Terraform state, HA witness storage, Azure Files NFS, and Azure NetApp Files |
| Credentials and encryption | New or existing Azure Key Vault instances and organization-managed keys |

Azure service and SKU availability varies by region and subscription. Validate
quota, feature registration, zones, VM SKUs, storage, and networking in the
target subscription before deployment.

For the framework component and state relationships behind these checks, see
[SDAF architecture](architecture.md).
