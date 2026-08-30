# HA topology operator guide

Start with `docs/supportability.md`. A supported operating system, database, or
storage option does not make every combination valid.

## Decisions to confirm

1. Is HA required for SAP central services, the database, or both?
2. Which database platform and topology are being deployed?
3. For HANA, is the design scale-up or scale-out?
4. Which documented fencing/quorum option is approved?
5. Which documented shared-storage option fits the workload?
6. Does the target OS version satisfy the selected HA design?

## Published boundaries

- Azure Files NFS is for applicable shared SAP file systems, not database files.
- Azure NetApp Files can support applicable shared and database file systems.
- Custom NFS remains an organization-owned design.
- HANA-specific scale-out or ANGI guidance does not apply to other databases.
- Do not promise an HA topology where current support documentation is silent.

## Before deployment

Run the documented SAP-system validation step and confirm the selected
configuration provides all required cluster, fencing, load-balancer, and
shared-storage inputs.

For deployment, hand off to `sdaf-sap-system`. For an existing unhealthy
cluster, hand off to `sdaf-ha-diagnostics`.
