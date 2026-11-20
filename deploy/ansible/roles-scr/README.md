# SCR Roles — Overview

This directory contains all Ansible roles used by the **SAP System Copy and Refresh (SCR)** automation framework. Each role has a single, well-defined responsibility and is designed to be composable — roles call one another rather than duplicating logic.

---

## Directory Structure

```
roles-scr/
├── scr_common/              # Shared configuration and utility task files
├── scr_db_backup/           # HANA backup creation, upload, and restore manifest
├── scr_db_restore/          # Manifest-driven backup retrieval and DB-node staging
├── scr_kernel/              # SAP and DB kernel inventory, compare, and sync
├── scr_keys/                # Azure Key Vault credential retrieval
├── scr_log_function/        # Generic logging and Azure Blob Storage function
└── scr_system_discovery/    # Comprehensive SAP system fact gathering
```

---

## Roles at a Glance

| Role | Purpose | Called As |
|---|---|---|
| `scr_common` | Central defaults file; shared utility tasks | `vars_files:` (defaults) or `include_role tasks_from:` (tasks) |
| `scr_db_backup` | Creates HANA backups and publishes a checksummed restore manifest | `include_role` |
| `scr_db_restore` | Retrieves a manifest and verifies all backup files on the destination DB host | `include_role` |
| `scr_kernel` | SAP and DB kernel inventory, compare, and sync report | `include_role` |
| `scr_keys` | Pulls SSH credentials from Azure Key Vault via MSI | `include_role` |
| `scr_log_function` | Generic log appending and Azure Blob Storage CRUD (summary, detail, object, file) | `include_role` |
| `scr_system_discovery` | Discovers OS, SAP, DB, topology, network, and storage facts on each SAP host | `include_role` |

---

## How They Fit Together

The main entry point is `playbook_scr_initialize.yaml`. The end-to-end
flow has three phases: **initialize** (register/resume), **work**
(STEP 4–9 guarded by `scr_resume_from_step`, each ending with a
checkpoint that advances `last_completed_step`), and **finalize**
(post_tasks set run/job status + upload the captured ansible log).

```
playbook_scr_initialize.yaml
│
├── vars_files: scr_common/defaults/main.yaml   ← shared vars
│
├── PRE_TASKS  (run_once on ansible_play_hosts[0])
│   ├─ truncate /tmp/scr_ansible_run.log (in place)
│   ├─ scr_log_function activity=initialize action=register
│   │    → load global index, abort stale jobs, find/create Job + Run,
│   │      set scr_job_id, scr_run_id, scr_resume_from_step
│   ├─ broadcast identity facts to every host (hostvars[...])
│   ├─ STEP 1 — log_summary: "Logging initialized"
│   └─ STEP 2 — scr_keys (Key Vault) + log_summary
│
├── TASKS  (parallel across all hosts; each STEP guarded by
│         when: scr_resume_from_step | int <= N)
│   ├─ STEP 4  scr_system_discovery (source + dest)
│   ├─ STEP 5  fetch per-host discovery reports to controller
│   ├─ STEP 6  scr_kernel inventory (source + dest)
│   ├─ STEP 7  scr_kernel compare
│   ├─ STEP 8  write kernel sync report
│   ├─ STEP 9  build + store kernel sync state (object activity)
│   └─ every STEP ends with:
│        scr_log_function activity=checkpoint step=N description="..."
│        → logs STEP line + bumps last_completed_step in the index
│
└── POST_TASKS  (after every host finishes)
    ├─ append discovery + kernel reports to detail log
    ├─ compute final status: any failed host or discovery failure
    │    → Failed (retry-able — next run resumes), else Completed-Success
    ├─ scr_log_function activity=initialize action=update target=run
    ├─ scr_log_function activity=initialize action=update target=job
    ├─ scr_keys cleanup
    └─ upload /tmp/scr_ansible_run.log →
         scr-runs/job_<id>/run_<id>/ansible_run.log
```

### Restartability

If a run ends with status `Failed`, the **next** invocation of
`playbook_scr_initialize.yaml` re-uses the same Job, allocates a new
Run number, and sets `scr_resume_from_step = last_completed_step + 1`.
STEP blocks whose number is below that are skipped by the `when:` guard,
so work already done is not repeated. `Completed-Success`, `Aborted`,
and `Completed-Failed` are all terminal — the next invocation starts a
brand-new Job.

See [scr_log_function/README.md](scr_log_function/README.md) for the
full state machine and global index schema.

### Why `pre_tasks` / `tasks` / `post_tasks` layout?

- **`pre_tasks`**: Runs once on every host *before* the main task block.
  Used for setup (log truncate, register run, broadcast identity facts,
  credentials) that must complete before work starts.
- **`tasks`**: The main parallel work — discovery and kernel steps run on
  multiple SAP hosts (`X90_PAS`, `X90_DB`, `X91_PAS`, `X91_DB`).
- **`post_tasks`**: Runs only *after* every host has finished its `tasks`
  block. This guarantees all per-host artifacts are on the controller
  before the final status update and ansible-log upload — no race.

---

## Running the Playbook

### Full run (all steps)

```bash
cd /home/azureadm/DHRUV-SCR-TESTING/sap-automation/deploy/ansible

ansible-playbook \
  --inventory x_scr_testing_inventory_X90.yaml \
  --inventory x_scr_testing_inventory_X91.yaml \
  --extra-vars "scr_source_sid=X90 scr_dest_sid=X91" \
  playbook_scr_initialize.yaml
```

### Selective runs using tags

Each step has a tag so you can run only what you need:

| Tag | What it runs |
|---|---|
| `logging` | Step 1 — Register run in global index, broadcast `scr_job_id`/`scr_run_id`, write summary log header |
| `secrets` | Step 2 — Pull SSH credentials from Azure Key Vault |
| `discovery` | Step 4 — Run system discovery on all SAP hosts |
| `fetch` | Step 5 — Fetch per-host reports, log STEP 4-5 |
| `kernel` | Steps 6-9 — SAP kernel inventory, compare, reports, log STEP 6-9 |
| `upload` | pre_tasks / post_tasks — write and upload summary log, upload artifacts to filestore |
| `cleanup` | Cleanup — Remove temp SSH key files; mark Run + Job complete in the global index |
| `always` | Setup tasks that always run regardless of other tags (date/time facts, Job+Run id register, broadcast) |

```bash
# Discovery only
ansible-playbook ... --tags "discovery,fetch"

# Skip cleanup (leave keys in place for debugging)
ansible-playbook ... --skip-tags "cleanup"

# Just upload whatever is already in the log directory
ansible-playbook ... --tags "upload"
```

---

## Authentication

All roles use **MSI (Managed Identity)** — no client secrets or passwords are required. The deployer VM's managed identity must have the following RBAC assignments:

| Resource | Role Required |
|---|---|
| Azure Key Vault (`MKDS1EUS2SAP00user54B`) | Key Vault Secrets User |
| Storage Account (`mkds0eus2tfstate152`) | Storage Blob Data Contributor |

> **Why MSI?** The storage account has key-based authentication disabled (`KeyBasedAuthenticationNotPermitted`). MSI is the only supported auth mode. The `az storage blob upload --auth-mode login` CLI command is used instead of the `azure_rm_storageblob` Ansible module for this reason.

---

## Azure Blob Storage Layout

Most SCR artifacts are **job-scoped** (so they accumulate across resume
attempts of the same Job). Only the captured ansible-playbook output is
**run-scoped**.

```
tfstate/
└── scr-runs/
    ├── scr_global_index.json                  ← global index of all Jobs and Runs
    └── job_<NNNN>/                            ← e.g. job_0007/
        ├── logs/                              ← job-scoped (appended across runs)
        │   ├── <job_id>_summary.log
        │   └── <job_id>_detail.log
        ├── object_store.json                  ← job-scoped Ansible facts
        ├── FILE_STORE/                        ← job-scoped uploaded files
        │   └── <filename>
        └── run_<NNNN>/                        ← e.g. run_0001/
            └── ansible_run.log                ← full ansible output for this attempt
```

See [scr_log_function/README.md](scr_log_function/README.md) for the
full Job+Run identity model, status state machine, and global-index
schema.

---

## Role READMEs

Each role has its own detailed README:

- [`scr_common/README.md`](scr_common/README.md) — Shared defaults and utility tasks
- [`scr_kernel/readme.md`](scr_kernel/readme.md) — SAP and DB kernel inventory, compare, and sync
- [`scr_keys/readme.md`](scr_keys/readme.md) — Azure Key Vault SSH credential retrieval (MSI)
- [`scr_log_function/README.md`](scr_log_function/README.md) — Generic logging and Azure Blob Storage function
- [`scr_system_discovery/README.md`](scr_system_discovery/README.md) — SAP system fact discovery

---

## Future Roles (Planned)

| Role | Purpose |
|---|---|
| `scr_parity` | Pre-copy parity validation (OS, SAP kernel, DB kernel) |
| `scr_refresh` | Database refresh orchestration |

The utility task files `scr_common/tasks/build_scr_state.yaml` and `scr_common/tasks/add_step_marker.yaml` are already in place and will be wired up as these future roles are added.
