# HA diagnostic evidence

Collect evidence before proposing any state-changing action.

## Cluster status

| OS family | Read-only status command |
| --- | --- |
| SUSE | `crm status full` |
| Red Hat | `pcs status --full` |

Preserve the complete output, timestamps, node names, failed actions, resource
placement, fencing history, and quorum state.

## SAP and database evidence

- Record the SAP SID and instance layout.
- Capture current primary/secondary roles and replication status.
- Capture the first failed operation and its timestamp.
- Retain the SDAF QA report and execution log when available.
- Confirm whether the request is diagnosis or an approved disruptive test.

## Stop conditions

Stop before cleanup, migration, fencing, resource moves, or service restarts.
Those actions require the documented owner workflow and explicit approval.

Sources: `docs/local/07-10-quality-assurance.md`,
`docs/local/troubleshooting.md`, and `docs/supportability.md`.
