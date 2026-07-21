# Role: scr_keys

Retrieves SSH credentials (username + private key) from **Azure Key Vault**
using the deployer VM's **Managed Identity (MSI)** and exposes them as
per-host Ansible facts (`ansible_user`, `ansible_ssh_private_key_file`)
so subsequent tasks can SSH into the SAP source and target systems
without any static secrets on disk.

The typical calling pattern is to include the role once for the
**source** system and once for the **destination** system before any
work runs, and then again with `cleanup: true` at the end of the play
to shred the temporary key files from the controller.

> This is the first role in the SCR framework — see
> [`../README.md`](../README.md) for the overall directory layout and
> the list of planned follow-up roles.

---

## Calling Convention

```yaml
- name:                             "Source - Get SSH credentials from Key Vault"
  ansible.builtin.include_role:
    name:                           roles-scr/scr_keys
  vars:
    function:                       "source"                                                # source | dest
    granularity:                    "workload"                                              # workload | sid | host
    kv_name:                        "{{ lookup('vars', 'scr_' + function + '_kv_name') }}"  # scr_source_kv_name
    prefix:                         "{{ lookup('vars', 'scr_' + function + '_prefix' ) }}"  # scr_source_prefix
  when:
    - (vars['scr_' + function + '_sid'] | upper) + '_PAS' in vars['group_names'] or
      (vars['scr_' + function + '_sid'] | upper) + '_DB'  in vars['group_names']
  tags:                             [secrets]
```

Cleanup at the end of the play:

```yaml
- name:                             "Cleanup - Remove temp SSH key files"
  ansible.builtin.include_role:
    name:                           roles-scr/scr_keys
  vars:
    cleanup:                        true
  tags:                             [cleanup]
```

---

## Inputs

| Variable      | Required | Values                       | Purpose                                                                                          |
|---------------|----------|------------------------------|--------------------------------------------------------------------------------------------------|
| `function`    | yes      | `source` \| `dest`           | Selects which side we are fetching credentials for. Drives the dynamic lookup of `scr_<function>_sid`. |
| `granularity` | yes      | `workload` \| `sid` \| `host`| Level at which SSH keys are managed in Key Vault (see the naming matrix below).                  |
| `kv_name`     | yes      | Key Vault name               | Key Vault to read from. Typically `scr_source_kv_name` / `scr_dest_kv_name` from `x_scr_parameters.yaml`. |
| `prefix`      | yes      | e.g. `MKDS1-EUS2-SAP00`      | Prefix for the Key Vault secret names. Typically `<ENVIRONMENT>-<REGION>-<WORKLOAD_ZONE>`.       |
| `cleanup`     | no       | `true` \| `false` (default)  | When `true`, skips secret retrieval and instead deletes the temp key files on the controller.    |

### Variables expected in the surrounding scope

The role does **not** define these — the playbook must set them before
`include_role`:

| Variable         | Example  | Used for                                                        |
|------------------|----------|-----------------------------------------------------------------|
| `scr_source_sid` | `X90`    | Reached via `vars['scr_' + function + '_sid']` when `granularity = sid`. |
| `scr_dest_sid`   | `X91`    | Same, for the target system.                                    |
| `msi_client_id`  | *(opt.)* | Optional client_id passed through to the Key Vault module. Defaults to omit — pick default MSI. |

---

## Outputs

The role sets the following **per-host** facts on every host in
`ansible_play_hosts` (via `set_fact` inside a `delegate_to: localhost`
block — the facts land on the original inventory host, not on
localhost):

| Fact                            | Purpose                                                                              |
|---------------------------------|--------------------------------------------------------------------------------------|
| `ansible_user`                  | SSH username retrieved from `<prefix>-sid-username[...]`.                            |
| `ansible_ssh_private_key_file`  | Path to the SSH private key on the controller (`/tmp/ansible_kv_key_<hostname>`, mode `0600`). |

Both facts are addressable per host with
`hostvars[<host>]['ansible_ssh_private_key_file']` etc.

> **`ansible_ssh_common_args`** is intentionally **not** set by this
> role. If your environment needs SSH options like
> `-o StrictHostKeyChecking=no`, define `ansible_ssh_common_args` in the
> inventory or in the playbook — the retrieved key will honour it.

---

## Key Vault Secret Naming

Secret names are constructed from `prefix`, a fixed `-sid-` infix, the
secret kind (`username` or `sshkey`), and an optional discriminator
determined by `granularity`:

| `granularity` | Username secret                            | Private-key secret                       |
|---------------|--------------------------------------------|------------------------------------------|
| `workload`    | `<prefix>-sid-username`                    | `<prefix>-sid-sshkey`                    |
| `sid`         | `<prefix>-sid-username-<SID>`              | `<prefix>-sid-sshkey-<SID>`              |
| `host`        | `<prefix>-sid-username-<inventory_hostname>` | `<prefix>-sid-sshkey-<inventory_hostname>` |

Where `<SID>` is `scr_source_sid` when `function = source`, and
`scr_dest_sid` when `function = dest`. See
[vars/main.yaml](vars/main.yaml) for the exact Jinja expressions.

If a granularity yields a secret name that does not exist in the vault,
the fact is set to the sentinel string `"UNSUPPORTED GRANULARITY"`
instead of failing hard — this makes the mis-configuration obvious in
the recap output.

---

## File Layout

```
scr_keys/
├── README.md
├── vars/
│   └── main.yaml           # Secret-name templates per granularity + cleanup default
└── tasks/
    ├── main.yaml           # Dispatcher: get_secrets OR cleanup based on `cleanup` var
    ├── get_secrets.yaml    # Identity check, fetch username + private key, write key file, recap
    └── cleanup.yaml        # Remove /tmp/ansible_kv_key_<host> from the controller
```

### `tasks/main.yaml`

Two mutually-exclusive `include_tasks` calls guarded by `cleanup`:

```yaml
- include_tasks: get_secrets.yaml   when: not (cleanup | default(false) | bool)
- include_tasks: cleanup.yaml       when:      cleanup | default(false) | bool
```

### `tasks/get_secrets.yaml`

Everything in this file is `delegate_to: localhost` — the Key Vault is
only ever reached from the controller (the deployer VM). Sensitive
blocks are wrapped in `no_log: true`.

1. `az account show` — logs the effective subscription and identity
   (tagged `silent_v1`).
2. Debug print of calling parameters (verbosity 1 only).
3. **Fetch username** with `azure.azcollection.azure_rm_keyvaultsecret_info`
   using `auth_source: msi`. 5 retries, 1s delay.
4. `set_fact: ansible_user` — the fact lands on the original inventory
   host because `set_fact` under `delegate_to` still targets the
   inventory host by default.
5. **Fetch private key** the same way.
6. Write it to `/tmp/ansible_kv_key_<inventory_hostname>` with mode
   `0600` on the controller and set `ansible_ssh_private_key_file` to
   that path.
7. Recap `debug:` (verbosity 0) with the resolved facts.

### `tasks/cleanup.yaml`

Removes `{{ ansible_ssh_private_key_file }}` on the controller so no key
material is left behind. Runs in the context of each inventory host but
`delegate_to: localhost` ensures a single deletion per unique path on
the controller.

---

## Authentication

The role uses **MSI only** — `auth_source: msi` on
`azure.azcollection.azure_rm_keyvaultsecret_info`. No client secrets,
no certs, no environment variables. The deployer VM's system-assigned
(or user-assigned, via `msi_client_id`) identity must have:

| Resource      | Role                    |
|---------------|-------------------------|
| Target Key Vault | **Key Vault Secrets User** |

If the identity is missing this permission the Key Vault module fails
with a 403; the role's 5 retries will not help — grant the RBAC
assignment and re-run.

---

## Tags

Non-secret bookkeeping tasks use two silent tags so they can be skipped
in noisy runs:

| Tag        | Applied to                                                                 |
|------------|----------------------------------------------------------------------------|
| `silent_v1`| `az account show` and the debug print of calling parameters.               |
| `silent_v2`| Every task inside the Key-Vault fetch / key-write blocks.                  |

Skip the identity chatter with `--skip-tags silent_v1`, or hide the
Key-Vault fetch traces with `--skip-tags silent_v2`. The recap `debug:`
runs at verbosity 0 and is not tagged, so a normal run still shows the
resolved facts.

Callers typically also apply `[secrets]` / `[cleanup]` tags on the
`include_role` itself so the whole role can be included or excluded by
tag from the top-level playbook.

---

## Typical Play Structure

A calling playbook is expected to include the role three times — once
per side in `pre_tasks`, then once with `cleanup: true` in `post_tasks`:

```
pre_tasks
├── scr_keys  (function=source, granularity=workload)  ─► ansible_user + ansible_ssh_private_key_file on every source host
└── scr_keys  (function=dest,   granularity=workload)  ─► ...on every destination host

tasks
└── ...work steps use the SSH facts to reach the SAP hosts...

post_tasks
└── scr_keys  (cleanup=true)  ─► shreds /tmp/ansible_kv_key_<host> on the controller
```

---

## Security Notes

- Secret retrieval and key-file write are inside `no_log: true` blocks,
  so the private key never appears in Ansible output or the captured
  `log_path` file.
- The private key file is written with mode `0600` and only exists on
  the controller for the lifetime of the play (removed by the cleanup
  path).
- All Azure access is via MSI — no long-lived credentials live in
  inventories, vars files, or environment variables.
- `gather_facts: false` on the top-level play is important — fact
  gathering would attempt SSH **before** this role has populated
  `ansible_user` / `ansible_ssh_private_key_file`, and would fail.

---

## Known Limitations / TODOs

Tracked inline in the source — see the `# TODO:` comments:

- `vars/main.yaml` — Refactor to construct only the single variable
  actually used for the requested granularity, rather than defining all
  three variants.
- `vars/main.yaml` — Consider not relying on the out-of-scope variables
  `scr_source_sid` / `scr_dest_sid`; take the SID as an explicit role
  input.
- `tasks/get_secrets.yaml` — Replace the `az account show` shell-out
  with `azure.azcollection.azure_rm_account_info` once the module is
  stable enough for our runners.
- On missing secrets the fact is set to `"UNSUPPORTED GRANULARITY"`
  rather than failing the play. Downstream SSH tasks will then fail
  with a less obvious error. A future revision could `fail:` early with
  the resolved secret name to make mis-configuration self-diagnosing.
