# SCR Roles — Overview

This directory holds the Ansible roles used by the **SAP System Copy
and Refresh (SCR)** automation framework. Each role has a single,
well-defined responsibility and is designed to be composable — roles
call one another rather than duplicating logic.

This PR introduces the framework's first role, **`scr_keys`**.
Additional roles are planned in follow-up PRs (see [Future
Roles](#future-roles-planned) below).

---

## Directory Structure

```
roles-scr/
├── README.md
└── scr_keys/                # Azure Key Vault SSH credential retrieval (MSI)
```

---

## Roles at a Glance

| Role       | Purpose                                                              | Called As      | Status  |
|------------|----------------------------------------------------------------------|----------------|---------|
| `scr_keys` | Pulls SSH credentials (username + private key) from Azure Key Vault via MSI and exposes them as per-host Ansible facts. | `include_role` | Shipped |

See [`scr_keys/README.md`](scr_keys/README.md) for the detailed role
documentation (inputs, outputs, secret-name matrix, tags, and security
notes).

---

## Authentication

All SCR roles authenticate to Azure via **MSI (Managed Identity)** — no
client secrets, no certs, no environment variables. The deployer VM's
system-assigned (or user-assigned, via `msi_client_id`) managed identity
must have the appropriate RBAC assignment on the target resource.

For `scr_keys`, that is **Key Vault Secrets User** on the Key Vault
being read from.

---

## Future Roles (Planned)

The following roles are planned in follow-up PRs. They are listed here
so contributors can see the overall shape of the framework the current
role slots into.

| Role                   | Purpose                                                                                                       |
|------------------------|---------------------------------------------------------------------------------------------------------------|
| `scr_common`           | Central defaults file and shared utility task files consumed by the other SCR roles.                          |
| `scr_log_function`     | Generic logging + Azure Blob Storage CRUD (summary log, detail log, object store, file store), Job/Run identity, and checkpoint/resume state machine. |
| `scr_system_discovery` | Discovers OS, SAP, DB, topology, network, and storage facts on each SAP host.                                 |
| `scr_kernel`           | SAP and DB kernel inventory, compare, and sync report.                                                        |
| `scr_parity`           | Pre-copy parity validation (OS, SAP kernel, DB kernel).                                                       |
| `scr_refresh`          | Database refresh orchestration.                                                                               |

Each new role will land with its own README documenting inputs,
outputs, and calling convention, and this overview will be updated to
add it to [Roles at a Glance](#roles-at-a-glance).
