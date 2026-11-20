# Role: scr_common

Central configuration and shared utility tasks for the SCR automation framework. This role is the single source of truth for all shared variables — Azure connection details, SID pairs, Key Vault names, log directory paths, and workflow parameters.

---

## How `scr_common` Is Used

Unlike the other SCR roles, `scr_common` is **not** called with `include_role`. Instead its defaults file is loaded directly via `vars_files:` at the top of the playbook. This is intentional — `vars_files` loads the values for *every* host in the play before any task runs, which is required for variables like `scr_log_dir` and `scr_azure_*` to be available on the controller and all remote hosts simultaneously.

```yaml
# In playbook_scr_initialize.yaml
vars_files:
  - roles-scr/scr_common/defaults/main.yaml
```

The task files inside `tasks/` are called explicitly via `tasks_from:` when needed:

```yaml
- ansible.builtin.include_role:
    name:       roles-scr/scr_common
    tasks_from: build_scr_state.yaml
```

---

## File Structure

```
scr_common/
├── defaults/
│   └── main.yaml            ← all shared variables (loaded via vars_files)
└── tasks/
    ├── main.yaml            ← empty stub (allows include_role to succeed)
    ├── build_scr_state.yaml ← builds the structured SCR state document (future use)
    └── add_step_marker.yaml ← appends telemetry markers to the state doc (future use)
```

---

## Variables

All variables live in `defaults/main.yaml`. They are **lowest-priority defaults** — any value can be overridden via inventory vars, group vars, or `--extra-vars`.

### Controller Paths

| Variable | Default | Description |
|---|---|---|
| `scr_log_dir` | `$HOME/scr/logs` | Directory on the deployer/controller where log files are written |
| `scr_datastore_root` | `$HOME/scr/datastore` | Root for local SCR datastore (future use) |

### Run Identity

| Variable | Default | Description |
|---|---|---|
| `scr_job_id` | _set at runtime_ | Job number (`%04d`); allocated by `scr_log_function` `index/register` |
| `scr_run_id` | _set at runtime_ | Run number within the Job (`%04d`); allocated by `scr_log_function` `index/register` |

> **Note:** `scr_job_id` and `scr_run_id` are set on `ansible_play_hosts[0]` by
> the `index/register` call (which runs `run_once: true`). Every other host
> picks them up via a broadcast `set_fact` that reads
> `hostvars[ansible_play_hosts[0]]`. See `scr_log_function/README.md` for
> details on the Job + Run identity model.

### Azure Blob Storage

| Variable | Value | Description |
|---|---|---|
| `scr_azure_subscription_id` | `02993e58-...` | Azure subscription |
| `scr_azure_resource_group` | `MKDS0-EUS2-SAP_LIBRARY` | Resource group containing the storage account |
| `scr_azure_storage_account` | `mkds0eus2tfstate152` | Storage account for SCR artifacts |
| `scr_azure_container` | `tfstate` | Blob container; SCR files land under the `scr-runs/` prefix |

### Authentication

| Variable | Value | Description |
|---|---|---|
| `scr_azure_use_managed_identity` | `true` | Use MSI — no client secrets required |
| `scr_auth_mode` | `msi` | Authentication mode consumed by `scr_log_function` and other roles |

> The storage account has key-based auth disabled. All storage operations use `az storage blob upload --auth-mode login` (MSI). The deployer VM's managed identity must have **Storage Blob Data Contributor** on the storage account.

### Source System

| Variable | Default | Description |
|---|---|---|
| `scr_source_sid` | `X90` | SAP SID of the source system |
| `scr_source_prefix` | `MKDS1-EUS2-SAP00` | Key Vault object name prefix for source credentials |
| `scr_source_kv_name` | `MKDS1EUS2SAP00user54B` | Azure Key Vault name for source SSH keys |

### Destination System

| Variable | Default | Description |
|---|---|---|
| `scr_dest_sid` | `X91` | SAP SID of the destination/target system |
| `scr_dest_prefix` | `MKDS1-EUS2-SAP00` | Key Vault object name prefix for destination credentials |
| `scr_dest_kv_name` | `MKDS1EUS2SAP00user54B` | Azure Key Vault name for destination SSH keys |

> **Important:** `scr_source_sid` and `scr_dest_sid` must *also* be passed via `--extra-vars` at runtime. The playbook's `hosts:` pattern uses these values to resolve the target host groups, and `hosts:` is evaluated *before* `vars_files` is loaded. `--extra-vars` is the only variable source available that early.

### SCR Workflow Parameters (Future Use)

| Variable | Default | Description |
|---|---|---|
| `scr_db_type` | `hana` | Database type: `hana`, `oracle`, `ase` |
| `scr_refresh_protocol` | `service` | Copy method: `service`, `local`, `snapshot`, `export_import` |
| `scr_retained_tables` | `[{USR02, MANDT}]` | Tables preserved during DB refresh |
| `scr_parity` | `{os, sap_kernel, db_kernel: true}` | Which parity checks to enforce before copy |

---

## Utility Task Files

### `build_scr_state.yaml`

Builds the complete SCR state document from discovered facts. Creates a structured text file at `/tmp/scr_state.txt` that captures source and target system details, refresh configuration, and parity check requirements.

**Required variables:**
- `source_facts` — discovery output from `scr_system_discovery` for the source system
- `target_facts` — discovery output from `scr_system_discovery` for the target system
- `scr_run_id`, `scr_db_type`, `scr_refresh_protocol`, `scr_retained_tables`, `scr_parity`

**Status:** Task file exists; not yet called from `playbook_scr_initialize.yaml`. Will be wired in as part of the parity/pre-copy phase.

---

### `add_step_marker.yaml`

Appends a timestamped step marker to the SCR state document for auditing and restart capability.

**Required variables:**
- `scr_step_name` — name of the step being marked (e.g. `"kernel_parity_check"`)
- `scr_step_status` — one of: `started`, `completed`, `failed`, `skipped`
- `scr_step_details` *(optional)* — dict of additional key/value context

**Example call:**

```yaml
- ansible.builtin.include_role:
    name:       roles-scr/scr_common
    tasks_from: add_step_marker.yaml
  vars:
    scr_step_name:   "system_discovery"
    scr_step_status: "completed"
    scr_step_details:
      source_sid: "{{ scr_source_sid }}"
      target_sid: "{{ scr_dest_sid }}"
```

**Status:** Task file exists; not yet called from the current playbook. Will be wired in as the workflow gains more steps.
