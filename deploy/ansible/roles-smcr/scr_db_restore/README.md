# SCR HANA Database Restore

This role restores the backup files described by a manifest from Azure Blob
Storage to a HANA database node. It deliberately does not execute HANA recovery:
recovery is destructive and its exact command depends on MDC topology, tenant
mapping, target revision, encryption keys, and the required recovery point.

## Required variables

```yaml
db_restore_manifest_blob: "scr-runs/job_42/FILE_STORE/manifests/source-db/SCR_HDB_20260807_120000__source-db__manifest.json"
db_restore_expected_backup_side: "source"
db_restore_rollback_manifest_blob: "scr-runs/job_42/FILE_STORE/manifests/target-db/SCR_HDB_DEST_20260807_120000__dest__target-db__manifest.json"
db_sid: "HDB"
scr_azure_resource_group: "<resource-group-containing-tfstate-account>"
scr_azure_container: "tfstate"
```

Use the exact `RESTORE MANIFEST` paths written to the backup summary log. A
source refresh requires the destination manifest as
`db_restore_rollback_manifest_blob`; the role validates that rollback point
and confirms that every rollback blob still exists with the recorded size
before it transfers any source files. Set `db_restore_expected_prefix` as an
additional guard when invoking automation.
The role discovers the tfstate storage account; `scr_azure_storage_account` can
still be supplied explicitly when discovery is not appropriate.

## Reversible refresh workflow

First, protect both systems. This play now targets both DB groups and emits
separate `side=source` and `side=dest` manifest lines:

```bash
ansible-playbook \
   --inventory x_scr_testing_inventory_X90.yaml \
   --inventory x_scr_testing_inventory_X91.yaml \
   --extra-vars @x_scr_parameters.yaml \
   playbook_scr_db_test.yaml
```

Record both manifest paths and prefixes from the summary log. To stage the
source backup on the target, provide both paths. The destination protection
manifest is mandatory even though its files are not transferred in this phase:

```bash
ansible-playbook \
   --inventory x_scr_testing_inventory_X90.yaml \
   --inventory x_scr_testing_inventory_X91.yaml \
   --extra-vars @x_scr_parameters.yaml \
   --extra-vars "db_restore_manifest_blob=<source-manifest> db_restore_expected_backup_side=source db_restore_expected_prefix=<source-prefix> db_restore_rollback_manifest_blob=<dest-manifest>" \
   playbook_scr_db_restore.yaml
```

After the approved HANA recovery and validation window, restore the target to
its original state by staging the protected destination backup:

```bash
ansible-playbook \
  --inventory x_scr_testing_inventory_X90.yaml \
  --inventory x_scr_testing_inventory_X91.yaml \
  --extra-vars @x_scr_parameters.yaml \
  --extra-vars "db_restore_manifest_blob=<dest-manifest> db_restore_expected_backup_side=dest db_restore_expected_prefix=<dest-prefix>" \
  playbook_scr_db_restore.yaml
```

Source refresh and target rollback are intentionally separate invocations. This
creates a human validation and approval gate before the target is returned to
its pre-refresh state.

## Restore sequence

1. Confirm the backup job completed and select its manifest. Never combine
   files or manifests from different backup prefixes.
2. Confirm source and target HANA revisions are restore-compatible. Patch the
   target first when required.
3. Confirm the target topology, instance number, tenant names, filesystem
   capacity, backup encryption keys, root keys, and licenses are available.
4. Run the protection playbook and retain both source and target manifests. The
   source refresh phase will fail unless the target rollback manifest validates.
5. Stop SAP application instances and integrations. Quiesce schedulers,
   interfaces, replication, monitoring actions, and inbound traffic.
6. Run this role against the destination DB host. It downloads each blob to
   the controller, verifies SHA-1, streams it to its original `DB_*` relative
   path below `db_restore_root`, verifies SHA-1 again, and removes staging.
7. Validate that every manifest entry exists on every required HANA node. For
   scale-out, use the matching source-host manifest for each destination node.
8. Stop HANA cleanly and disable automatic restart or cluster takeover for the
   recovery window. Record the pre-restore service state.
9. Use HANA Cockpit, HANA Studio, or the SAP-supported recovery command for the
   installed revision to recover SYSTEMDB from the manifest's
   `backup_prefix`. Choose the required data/log recovery mode and point in
   time. For a system copy, apply the approved source-to-target tenant mapping.
10. Recover or recreate tenant databases as required by the MDC recovery plan.
    Do not assume SYSTEMDB recovery alone restores every tenant in every HANA
    revision and topology.
11. Start HANA and verify nameserver/indexserver services, database and tenant
    state, trace files, backup catalog, persistence, and consistency checks.
12. Perform SAP post-copy work: secure-store and RFC updates, logical system
    handling, profiles, batch jobs, printers, interfaces, licenses, users,
    certificates, and environment-specific endpoints.
13. Start SAP in dependency order, execute application smoke tests and business
    validation, then re-enable integrations, monitoring, HA, and replication.
14. After validation, use the `dest` manifest to recover the original target,
    then repeat database, SAP, interface, and business validation.
15. Retain both manifests, recovery logs, command output, validation evidence,
    timestamps, and operator approvals in the SCR job record.

Test file placement first with a non-production target. Obtain the exact HANA
recovery command from the runbook for the installed HANA revision; do not place
database passwords directly on a command line.
