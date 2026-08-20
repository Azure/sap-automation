---
name: sdaf-ha-topology
description: >
  Choose the documented SDAF high-availability design before SAP-system
  deployment. Use when a user asks which HA topology to deploy, whether to use
  AFA or SBD, AFS or ANF, HANA scale-up or scale-out, whether ANGI is allowed,
  or which HA inputs must be set before deployment. Ground answers in the
  current support matrix, Ansible roles, sample tfvars, and validation logic.
  Do NOT use for live cluster diagnosis (sdaf-ha-diagnostics) or for running
  the installers (sdaf-sap-installation).
allowed-tools: shell
license: MIT
---

# SDAF HA Topology

Context-primer for **pre-deploy** HA design. Keep this skill short and route to
[`references/topology-decision-guide.md`](references/topology-decision-guide.md)
for the detailed OS/DB/storage matrices, sample-backed examples, and source
map.

## When to invoke

Trigger on:

- "Which SDAF HA topology should I use?"
- "AFA or shared-disk / iSCSI quorum?"
- "AFS or ANF for this SAP HA design?"
- "Should HANA stay scale-up or move to scale-out?"
- "Can I enable SAPHanaSR-angi on this OS release?"
- "What HA inputs do I need in system tfvars before deployment?"

Do NOT trigger on:

- a live cluster failure, fencing event, or `crm` / `pcs` diagnosis — use
  `sdaf-ha-diagnostics`
- running numbered install stages or partial-install recovery — use
  `sdaf-sap-installation`
- generic SAP-system Terraform deployment without an HA design question — use
  `sdaf-sap-system`

## Preconditions

Before answering, know or ask for:

- target operating system and version
- target database platform
- whether HA is required for central services, the database tier, or both
- whether the question is design-time or an already-deployed cluster problem

## Decision loop

1. **Confirm the support boundary first.** Start with
   [`docs/supportability.md`](../../docs/supportability.md). A listed OS,
   database, or storage option does **not** make every cross-combination valid.
   If the requested combination is not explicitly backed by current docs and
   code, say docs are silent and stop.
2. **Split the question into layers.** Treat HA as separate design choices for:
   - SAP central services: `scs_server_count`, `scs_high_availability`,
     `scs_cluster_type`
   - database tier: `database_high_availability`, `database_cluster_type`, and
     for HANA `database_HANA_use_scaleout_scenario`
3. **Confirm the documented platform path.** Use
   `docs/supportability.md` and the current SAP-system input documentation.
   Do not infer that every listed database has an SDAF-managed HA topology.
4. **Choose quorum / fencing deliberately.** The tfvar contract exposes `AFA`,
   `ASD`, and `ISCSI` for both SCS and DB tiers. AFA needs fencing credentials
   unless `use_msi_for_clusters = true`. ASD / ISCSI take the SBD path, so the
   OS release must satisfy the current role gates before cluster creation.
5. **Choose shared storage deliberately.** Use current docs and mount logic:
   - `AFS` for shared SAP file systems only
   - `ANF` for applicable shared and database file systems
   - custom `NFS` as organization-owned design, not a Microsoft-owned reference
6. **Handle HANA-only forks explicitly.** For HANA, decide scale-up vs
   scale-out and, separately, whether `use_hanasr_angi` is allowed on the
   target OS. Do not apply scale-out or ANGI guidance to Oracle, DB2, ASE, or
   SQL Server.
7. **Route rather than guess.** If the user is asking how to deploy the chosen
   design, hand off to `sdaf-sap-system`. If the user is asking why an existing
   cluster failed, hand off to `sdaf-ha-diagnostics`.

## Validate before deployment

Use the documented SAP-system validation step as the pre-deploy gate. For HA
answers, make sure the selected path can supply:

- cluster-aware base inputs: `database_high_availability`,
  `database_cluster_type`, `scs_high_availability`, `scs_cluster_type`,
  `use_msi_for_clusters`, `platform`
- for SCS HA: shared storage, `NFS_provider`, and central-services
  load-balancer inputs
- for AFA without MSI: fencing client ID, password, subscription, and tenant
- for HANA / DB2 AFA database HA: the database load-balancer IP
- for HANA scale-out: standby / observer / shared-storage inputs that match the
  selected path

## Hard safety rules

- Do not infer support from one sample, one BOM, or one tfvar alone.
- Do not promise an ASE database-HA topology from the current DB-HA playbook.
- Do not apply HANA-only scale-out or ANGI guidance to non-HANA databases.
- Do not use Azure Files NFS as a database-file-system answer.
- Do not generalize Pacemaker validation guidance to Windows clustering.
- If docs, samples, and current roles disagree, stop and call out the mismatch.

## Hand-off

- deploy the chosen infrastructure path -> `sdaf-sap-system`
- run OS / DB / SAP install stages -> `sdaf-sap-installation`
- diagnose a live cluster or fencing issue -> `sdaf-ha-diagnostics`
- run post-deploy HA checks -> `sdaf-quality-assurance`
