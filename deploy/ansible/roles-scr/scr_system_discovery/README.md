# Role: scr_system_discovery

Performs comprehensive fact gathering on a SAP host. Collects OS, SAP kernel, database, topology, network, and storage information and writes a human-readable report to `/tmp/` on the remote host. The report is later fetched to the controller and uploaded to Azure Blob Storage.

---

## What It Does

Runs on each SAP host (PAS and DB for both source and destination) and gathers:

| Category | What Is Collected |
|---|---|
| **OS** | Distribution, version, kernel version, CPU, memory, uptime, virtualisation |
| **SAP** | SID, kernel version, SAP services status, profile details |
| **Database** | DB type, version, running status |
| **Topology** | Architecture, SCS host, SCS instance number, app servers, cluster status |
| **Network** | Interfaces, IP addresses, gateway, DNS servers, SAP port availability |
| **Storage** | LVM/RAID config, free space, SAP filesystem mounts |

Results are consolidated into a report file:
```
/tmp/scr_discovery_<role>_<SID>_<epoch>.txt
```

---

## File Structure

```
scr_system_discovery/
├── defaults/
│   └── main.yaml                  ← default scope and settings
└── tasks/
    ├── main.yaml                  ← orchestration; calls all sub-tasks
    ├── discover_os_facts.yaml     ← OS and system info
    ├── discover_sap_facts.yaml    ← SAP SID, kernel, services
    ├── discover_db_facts.yaml     ← database version and status
    ├── discover_topology.yaml     ← SAP architecture, SCS, app servers
    ├── discover_network.yaml      ← network interfaces, ports, DNS
    ├── discover_storage.yaml      ← filesystems, LVM, disk usage
    └── consolidate_results.yaml   ← merge all facts → write .txt report
```

---

## Variables

### Core Discovery Settings

| Variable | Default | Description |
|---|---|---|
| `scr_discovery_system_role` | `source` | Role of this system: `source` or `target` |
| `scr_discovery_sid` | (empty) | Target SAP SID; auto-discovered if empty |

### Discovery Scope

Control which categories are collected. Set any to `false` to skip that category.

```yaml
scr_discovery_scope:
  os_facts:             true
  sap_facts:            true
  db_facts:             true
  topology:             true
  networking:           true
  storage:              true
  performance_baseline: false   # optional; disabled by default
```

### Output Settings

| Variable | Default | Description |
|---|---|---|
| `scr_discovery_output.update_scr_state` | `true` | Populate `scr_state_update` fact for use by `build_scr_state.yaml` |
| `scr_discovery_output.create_inventory` | `true` | Write the `.txt` report file to `/tmp/` |
| `scr_discovery_output.log_discoveries` | `true` | Log discovered values via `debug` tasks |

### Error Handling

| Variable | Default | Description |
|---|---|---|
| `scr_discovery_error_handling.continue_on_error` | `true` | Continue discovery if a sub-task fails |
| `scr_discovery_error_handling.required_facts` | `[sap_sid, os_info, sap_kernel]` | Facts that must succeed for the run to be considered valid |
| `scr_discovery_error_handling.optional_facts` | `[db_kernel, topology_details]` | Facts that can fail silently |

---

## How to Call This Role

The role is called once per system role (source and destination) from the playbook. Use `ignore_errors: true` so that a discovery failure on one host does not stop parallel discovery on the other hosts.

### From `playbook_scr_initialize.yaml`

```yaml
- name: "Source - System Discovery"
  ansible.builtin.include_role:
    name: roles-scr/scr_system_discovery
  vars:
    scr_discovery_system_role: "source"
    scr_discovery_sid:         "{{ scr_source_sid }}"
  when:
    - (scr_source_sid | upper + '_PAS') in group_names or
      (scr_source_sid | upper + '_DB')  in group_names
  ignore_errors: true
  tags: [discovery]

- name: "Destination - System Discovery"
  ansible.builtin.include_role:
    name: roles-scr/scr_system_discovery
  vars:
    scr_discovery_system_role: "target"
    scr_discovery_sid:         "{{ scr_dest_sid }}"
  when:
    - (scr_dest_sid | upper + '_PAS') in group_names or
      (scr_dest_sid | upper + '_DB')  in group_names
  ignore_errors: true
  tags: [discovery]
```

### Standalone — discover a single system

```yaml
- hosts: my_sap_host
  gather_facts: false
  tasks:
    - ansible.builtin.include_role:
        name: roles-scr/scr_system_discovery
      vars:
        scr_discovery_system_role: "source"
        scr_discovery_sid:         "PRD"
```

### With a reduced scope (OS and SAP only, skip DB/network/storage)

```yaml
    - ansible.builtin.include_role:
        name: roles-scr/scr_system_discovery
      vars:
        scr_discovery_system_role: "source"
        scr_discovery_sid:         "PRD"
        scr_discovery_scope:
          os_facts:   true
          sap_facts:  true
          db_facts:   false
          topology:   false
          networking: false
          storage:    false
```

---

## Output

### Report file on the remote host

Each host writes a `.txt` file to `/tmp/` upon completion:

```
/tmp/scr_discovery_source_X90_1711276200.txt
```

Contents include a full human-readable summary of all gathered facts (OS, SAP, DB, topology, network, storage).

### Fact variable: `discovered_facts`

The role sets a `discovered_facts` fact on each host with the consolidated data. This is available to subsequent tasks in the same play:

```yaml
discovered_facts:
  system_role:           "source"
  discovery_timestamp:   "2026-03-24T10:30:00Z"
  os:
    distribution:        "SLES"
    version:             "15.4"
    kernel:              "5.14.21-150400.24.81-default"
    ...
  sap:
    sid:                 "X90"
    kernel:              "7.85"
    ...
  db:
    type:                "hana"
    version:             "2.00.065"
    processes_running:   true
    ...
  topology:
    architecture:        "standard"
    scs_host:            "x90app00l5a4"
    app_server_count:    1
    cluster_configured:  false
    ...
  network:
    primary_ip:          "10.111.32.12"
    ...
  storage:
    lvm_configured:      true
    free_space_gb:       "450"
    ...
```

### Fetching reports to the controller

After all hosts finish discovery, the playbook fetches the `.txt` files and places them in `scr_log_dir` on the controller:

```yaml
- name: "Host - Find discovery report files in /tmp"
  ansible.builtin.find:
    paths:    "/tmp"
    patterns: "scr_discovery_*.txt"
  register: _scr_discovery_reports

- name: "Controller - Fetch each discovery report"
  ansible.builtin.fetch:
    src:  "{{ item.path }}"
    dest: "{{ scr_log_dir }}/scr_discovery_{{ inventory_hostname }}_{{ item.path | basename }}"
    flat: true
  loop: "{{ _scr_discovery_reports.files }}"
```

These fetched files are then uploaded to Azure Blob Storage by `scr_log_function` (`activity: file, action: store`) in `post_tasks`.

---

## Error Handling Behaviour

- **`any_errors_fatal: false`** is set on the play — a discovery failure on one host does not kill the play for other hosts.
- **`ignore_errors: true`** is set on the `include_role` call — the result is captured in `_source_discovery_result` / `_dest_discovery_result` and the outcome is written to the main log (`STEP 4: Discovery FAILED / completed — <hostname>`).
- Sub-tasks within the role use `ignore_errors: true` on individual gather commands so that a missing binary or permission issue on one check doesn't abort the entire discovery for that host.
