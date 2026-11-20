# Role: scr_log_function

Generic logging, indexing, and Azure-Blob-Storage CRUD function for SCR
automation. Every cross-cutting concern (registering a run, advancing a
checkpoint, appending a log line, persisting a fact, uploading a file)
goes through this single role with a uniform `activity` / `action` /
`payload` interface.

---

## Calling Convention

```yaml
- name:                                 "<description>"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           initialize | checkpoint | log_summary | log_detail | object | file
    action:                             register | update | store | retrieve | delete
    payload:                            <string | list | dict | fact name | file path>
  run_once:                             true       # in multi-host plays
```

---

## Activities and Actions

| Activity      | Actions                          | `payload`                                                                                                              | Notes |
|---------------|----------------------------------|------------------------------------------------------------------------------------------------------------------------|-------|
| `initialize`  | `register` / `update`            | `register` → `{ activity, source_sid, dest_sid }`. `update` → `{ target: run\|job\|step, status \| step }`             | Manages the global run index. `register` sets `scr_job_id`, `scr_run_id`, `scr_resume_from_step`. |
| `checkpoint`  | (no `action`)                    | n/a — pass `step: <int>` and `description: "<text>"`                                                                   | Writes a STEP summary line and advances `last_completed_step` in the index. Call at the end of every numbered step. |
| `log_summary` | `store`                          | string or list of strings                                                                                              | Appends timestamped line(s) to `<job_id>_summary.log` and re-uploads. |
| `log_detail`  | `store`                          | string / list of strings (default). With `payload_type: file_content`, a list of file paths to embed as raw content.   | Same as above for `<job_id>_detail.log`. |
| `object`      | `store` / `retrieve` / `update` / `delete` | Ansible fact name(s) — `fact_name` or `fact_name, host_name`                                                 | Serialises facts into the job-scoped `object_store.json`. |
| `file`        | `store` / `retrieve` / `update` / `delete` | Controller file path(s) — `path` or `path, host_name`                                                       | Pushes/pulls files to/from `FILE_STORE/` in the job folder. |

`activity: index` is **no longer accepted** — it was renamed to `initialize`.

---

## Job + Run Identity Model

SCR runs are organised into **Jobs** and **Runs**, similar to Azure DevOps
pipelines:

- A **Job** groups every attempt to copy/refresh a given `source_sid` →
  `dest_sid` pair.
- A **Run** is a single execution attempt within a Job. Run numbers reset to
  `0001` for each new Job.
- If the previous Job for the same SID pair is `Failed` (retry-able), the
  next `register` call **reuses** that Job and appends a new Run that
  **resumes** from `last_completed_step + 1`.
- Otherwise a new Job is created. Any leftover `Active` / `In-Progress`
  Jobs are first marked `Aborted` by the `abort_stale` phase.

### Run-status state machine

| Status              | Category       | Meaning                                                                |
|---------------------|----------------|------------------------------------------------------------------------|
| `Active`            | active         | Run currently executing (initial state set by `register`).             |
| `In-Progress`       | active         | Run mid-execution (reserved; not set automatically today).             |
| `Failed`            | retry-able     | Run finished with errors. The **next** `register` will reuse this Job and resume from `last_completed_step + 1`. |
| `Aborted`           | terminal       | Run never finished cleanly (e.g. process killed); cleared by the next `register`'s `abort_stale` phase. |
| `Completed-Success` | terminal       | Run finished cleanly. Next `register` creates a new Job.               |
| `Completed-Failed`  | terminal       | Manual "give up". Reserved for future use.                             |

`Failed` is the only state that causes the next register to **resume**;
every other terminal state starts a brand-new Job.

### Global index schema (`scr-runs/scr_global_index.json`)

```json
{
  "last_job_number": 7,
  "jobs": [
    {
      "job_id": 7,
      "activity": "SCR",
      "source_sid": "X90",
      "dest_sid": "X91",
      "status": "Active",
      "last_run_number": 2,
      "last_completed_step": 6,
      "runs": [
        {"run_id": 1, "start_date": "2026-05-28T18:00:00Z", "end_date": "2026-05-28T18:30:00Z", "status": "Failed"},
        {"run_id": 2, "start_date": "2026-05-28T19:00:00Z", "end_date": "",                    "status": "Active"}
      ]
    }
  ]
}
```

`last_completed_step` is updated by every `checkpoint` call and drives
`scr_resume_from_step` on the next register.

---

## Blob Layout in Azure (tfstate container)

Most artifacts are **job-scoped** so they accumulate across resume attempts.
Only the captured ansible-playbook output is **run-scoped**.

```
tfstate/
└── scr-runs/
    ├── scr_global_index.json                  ← global index (all Jobs, all Runs)
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

---

## End-to-End Flow

When [playbook_scr_initialize.yaml](../../playbook_scr_initialize.yaml) runs,
the role is invoked in this order:

1. **`pre_tasks`** (run-once on `ansible_play_hosts[0]`):
   - Truncate `/tmp/scr_ansible_run.log` **in place** so this run starts with
     a clean log file. (Must be in-place — `copy:` creates a new inode and
     ansible keeps writing to the deleted old file.)
   - `activity: initialize`, `action: register` →
     [initialize.yaml](tasks/initialize.yaml) dispatcher runs:
     - `initialize_load.yaml` — download `scr_global_index.json` (init empty on first run).
     - `initialize_abort_stale.yaml` — mark stale `Active`/`In-Progress` Jobs as `Aborted`.
     - `initialize_register.yaml` — find a reusable `Failed` Job or create a
       new one; set `scr_job_id`, `scr_run_id`, `scr_resume_from_step`.
     - `initialize_update.yaml` — no-op for register.
     - `initialize_write.yaml` — upload the updated index.
   - Broadcast `scr_job_id`, `scr_run_id`, `scr_resume_from_step` from
     `ansible_play_hosts[0]` to every host.
   - STEP 1 (`log_summary`) — write summary header.
   - STEP 2 (`log_summary`) — Key Vault secrets pulled by `scr_keys`.

2. **`tasks`** — work steps STEP 4–9, each guarded by
   `when: scr_resume_from_step | int <= N`. Every block ends with a
   **checkpoint** call that:
   - Appends `STEP N : <description>` to the summary log.
   - Calls `initialize` with `action: update, target: step` to advance
     `last_completed_step` in the global index.

   This is what makes resume work — on the next run, `register` reads
   `last_completed_step` and skips every block already done.

3. **`post_tasks`** (after every host finishes):
   - Append per-host discovery reports + kernel sync report to detail log.
   - Compute final run status: any failed host or discovery failure → `Failed`
     (retry-able), otherwise → `Completed-Success` (terminal).
   - `activity: initialize, target: run` to set the run status + `end_date`.
   - `activity: initialize, target: job` to set the job status.
   - SSH key cleanup.
   - Upload `/tmp/scr_ansible_run.log` to
     `scr-runs/job_<id>/run_<id>/ansible_run.log` (`failed_when: false` so
     a missing/failed upload never blocks the run).

---

## Ansible Run Log

The full ansible-playbook output is captured to `/tmp/scr_ansible_run.log`
via `log_path` in [ansible.cfg](../../ansible.cfg):

```ini
[defaults]
log_path = /tmp/scr_ansible_run.log
```

`log_path` appends forever, so the playbook truncates the file **in place**
in `pre_tasks` (`: > /tmp/scr_ansible_run.log`). Atomic-rename truncates
(`copy:`) break this — see the in-file comment for why.

For a one-off custom path, set `ANSIBLE_LOG_PATH` in the environment; the
upload task reads `ANSIBLE_LOG_PATH` and falls back to the configured
default.

---

## Examples

### Register a new SCR run

```yaml
- name:                                 "LOG - Register SCR run in global index"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           initialize
    action:                             register
    payload:
      activity:                         SCR
      source_sid:                       "{{ scr_source_sid }}"
      dest_sid:                         "{{ scr_dest_sid }}"
  run_once:                             true
  tags:                                 [logging, always]
```

After `register`, broadcast the resulting facts to every host —
`set_fact` inside `run_once: true` only lands on `ansible_play_hosts[0]`:

```yaml
- name:                                 "Controller - Broadcast SCR identity"
  ansible.builtin.set_fact:
    scr_job_id:                         "{{ hostvars[ansible_play_hosts[0]]['scr_job_id'] }}"
    scr_run_id:                         "{{ hostvars[ansible_play_hosts[0]]['scr_run_id'] }}"
    scr_resume_from_step:               "{{ hostvars[ansible_play_hosts[0]]['scr_resume_from_step'] | int }}"
  tags:                                 [logging, always]
```

### Checkpoint at the end of a step

```yaml
- name:                                 "CHECKPOINT - STEP 4 complete"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           checkpoint
    step:                               4
    description:                        "Discovery completed on all hosts"
  run_once:                             true
```

Guard the step itself with `when: scr_resume_from_step | int <= N`.

### Update run / job status

```yaml
- name:                                 "LOG - Mark current run completed"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           initialize
    action:                             update
    payload:
      target:                           run
      status:                           "{{ _scr_final_status }}"   # Completed-Success | Failed | ...
  run_once:                             true

- name:                                 "LOG - Mark current job completed"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           initialize
    action:                             update
    payload:
      target:                           job
      status:                           "{{ _scr_final_status }}"
  run_once:                             true
```

Always update `run` before `job` — the job-level update reads the current
job state after the run-level write.

### Append summary / detail lines

```yaml
- name:                                 "LOG - Starting compare"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           log_summary
    action:                             store
    payload:                            "Starting SAP Kernel Compare"
  run_once:                             true
```

```yaml
- name:                                 "LOG - Append discovery reports to detail log"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           log_detail
    action:                             store
    payload_type:                       file_content
    payload:                            "{{ _scr_discovery_txt_files.files | map(attribute='path') | list }}"
  run_once:                             true
```

### Store / retrieve a fact

```yaml
- name:                                 "Store kernel sync state"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           object
    action:                             store
    payload:                            scr_kernel_sync_state
  run_once:                             true
```

```yaml
- name:                                 "Retrieve kernel sync state"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           object
    action:                             retrieve
    payload:                            scr_kernel_sync_state
    result_var:                         loaded_sync_state
  run_once:                             true
```

### Store / retrieve / delete a file in FILE_STORE

```yaml
- name:                                 "Store files in FILE_STORE"
  ansible.builtin.include_role:
    name:                               roles-scr/scr_log_function
  vars:
    activity:                           file
    action:                             store          # or: update / retrieve / delete
    payload:
      - /tmp/FILE1
      - /tmp/FILE2, localhost
  run_once:                             true
```

For `retrieve`, the optional second token is the **destination directory** on
the controller; omit it to use `scr_log_function_local_filestore_dir`.

---

## File Structure

```
scr_log_function/
├── defaults/
│   └── main.yaml                  ← blob prefixes, local log dir defaults
└── tasks/
    ├── main.yaml                  ← storage-account discovery + activity router
    ├── initialize.yaml            ← dispatcher; imports the five phases below
    ├── initialize_load.yaml       ← download + normalise the global index
    ├── initialize_abort_stale.yaml← mark stale Active/In-Progress as Aborted (register only)
    ├── initialize_register.yaml   ← find/create Job, allocate Run, set identity facts
    ├── initialize_update.yaml     ← update target=run|job|step (update only)
    ├── initialize_write.yaml      ← upload index if a phase modified it
    ├── checkpoint.yaml            ← log STEP + advance last_completed_step
    ├── log_summary.yaml           ← append + upload <job_id>_summary.log
    ├── log_detail.yaml            ← append + upload <job_id>_detail.log
    ├── object.yaml                ← CRUD on Ansible facts (job-scoped object_store.json)
    ├── object_*.yaml              ← object sub-actions (store/retrieve/update/delete)
    ├── file.yaml                  ← CRUD on files in FILE_STORE
    └── file_*.yaml                ← file sub-actions (store/retrieve/update/delete)
```

`initialize.yaml` uses `import_tasks` with bare filenames; this only resolves
correctly when called via the role (so role context is set). External
callers must use `include_role: name: roles-scr/scr_log_function` with
`tasks_from:` — never raw `include_tasks:` with an absolute path.

---

## Variables

### Defaults (override via inventory or `--extra-vars`)

| Variable                                 | Default                                                              | Description                                                              |
|------------------------------------------|----------------------------------------------------------------------|--------------------------------------------------------------------------|
| `scr_log_function_local_log_dir`         | `{{ scr_basedir }}/logs`                                             | Local controller log directory.                                          |
| `scr_log_function_index_blob`            | `scr-runs/scr_global_index.json`                                     | Fixed blob path for the global index.                                    |
| `scr_log_function_remote_job_basedir`    | `scr-runs/job_<scr_job_id>`                                          | Job-scoped blob prefix (logs / object_store / FILE_STORE live here).     |
| `scr_log_function_remote_basedir`        | `scr-runs/job_<scr_job_id>/run_<scr_run_id>`                         | Run-scoped blob prefix (currently used only for `ansible_run.log`).      |
| `scr_log_function_remote_log_dir`        | `<job_basedir>/logs`                                                 | Where summary/detail logs land.                                          |
| `scr_log_function_remote_filestore_dir`  | `<job_basedir>/FILE_STORE`                                           | Where the `file` activity writes.                                        |
| `scr_log_function_remote_objectstore`    | `<job_basedir>/object_store.json`                                    | Where the `object` activity writes.                                      |

### Required at runtime

| Variable                       | Source                                                                |
|--------------------------------|-----------------------------------------------------------------------|
| `scr_azure_resource_group`     | Inventory `all: vars` — environment-specific.                         |
| `scr_azure_container`          | Default `tfstate` in `scr_common`.                                    |
| `scr_azure_storage_account`    | Auto-discovered from the resource group on first call (cached).       |
| `scr_job_id`, `scr_run_id`     | Set by `initialize/register` and broadcast in `pre_tasks`.            |
| `scr_resume_from_step`         | Set by `initialize/register`; drives `when:` guards on STEP blocks.   |

---

## Important Implementation Notes

### `import_tasks` vs `include_tasks` and tag propagation

`tasks/main.yaml` routes `initialize` with **`import_tasks`** (static)
because the `tags: always` annotation only reliably propagates through
imports. With `include_tasks` plus `--tags <something>`, tasks inside
`initialize.yaml` were silently skipped. Other activities use
`include_tasks` because they don't share that constraint.

### Calling `initialize.yaml` from another file in the role

[checkpoint.yaml](tasks/checkpoint.yaml) must call `initialize.yaml` to
advance `last_completed_step`. It uses
`include_role: name: roles-scr/scr_log_function` with
`tasks_from: initialize.yaml` rather than `include_tasks: file: <abs>`,
because the latter loses role context and the bare-name `import_tasks`
inside `initialize.yaml` fails with `NoneType` path errors.

### `set_fact` inside `run_once` lands on one host only

When `initialize/register` runs `run_once: true`, the resulting facts
(`scr_job_id`, `scr_run_id`, `scr_resume_from_step`) only land on
`ansible_play_hosts[0]`. Every other host must read them via
`hostvars[ansible_play_hosts[0]][...]`. The playbook's "Broadcast"
task does exactly this.

Do **not** add `delegate_to: localhost` to `set_fact` tasks — the `when:`
is still evaluated against the inventory host, which causes silent skips
when an intermediate fact lives on a different host.

### Native types templating + `to_json`/`from_json` round-trips

Earlier versions of `initialize_load.yaml` / `initialize_abort_stale.yaml`
used `to_json | from_json` to deep-copy a list of dicts. Under native types
the rendered JSON string is auto-parsed back to a list before `from_json`
can run, breaking the chain. Current code uses `set_fact` accumulator
loops (`init []` → `loop:` → `set_fact:` with `selectattr` / `rejectattr`
/ `map('combine', …)`) instead. Don't reintroduce the `to_json` pattern.

### In-place log truncation

The `pre_tasks` truncate uses `shell: ": > /tmp/scr_ansible_run.log"`
intentionally. `ansible.builtin.copy` (or any module that does
atomic-rename) creates a new inode; ansible's open log file handle keeps
writing to the deleted old inode and the new file stays empty.
