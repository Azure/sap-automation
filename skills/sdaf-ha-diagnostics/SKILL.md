---
name: sdaf-ha-diagnostics
description: >
  Diagnose a live or recently failed SDAF high-availability cluster without
  changing cluster state. Start read-first: capture `crm status full` or
  `pcs status --full`, inspect SBD or fencing evidence, confirm current
  resource placement, and reuse existing quality-assurance or HCMT artifacts.
  Grounded in `docs/local/07-10-quality-assurance.md`, the shipped Pacemaker
  role vars/tasks, and the SAP Automation QA setup role. Use when a user says
  "diagnose my HANA failover", "crm status", "pcs status", "check fencing",
  "why is the SCS/ERS cluster unhealthy", "offline_validation/cib", or
  "review an HCMT result zip". Do NOT use for pre-deploy topology or design
  choices (see `sdaf-ha-topology`), fresh installation/deploy, or disruptive
  failover/fencing exercises (see `sdaf-quality-assurance`).
allowed-tools: shell
license: MIT
---

# SDAF HA Diagnostics

Action-loop skill. Owns **read-first, safe diagnostics** for a live or
recently failed SDAF HA cluster. It does not choose the topology, move
resources, clean up stonith history, or invent a recovery procedure.

For the exact evidence ladder, current-code anchors, and stop-list, read
[`references/cluster-evidence.md`](references/cluster-evidence.md).

## When to invoke

Trigger on: "diagnose HA cluster", "HANA failover failed", "crm status",
"pcs status", "check fencing", "resource placement", "cluster unhealthy",
"offline_validation/cib", "HCMT result", "SCS/ERS failover", or "read the
current Pacemaker state".

Do NOT trigger on:

- pre-deploy design questions such as SBD vs Azure fence agent, ANF vs AFS,
  ANGI eligibility, distro choice, or scale-out design — route to
  `sdaf-ha-topology`;
- requests to run online failover, crash, fencing, or blocked-network tests —
  route to `sdaf-quality-assurance`;
- a broader SDAF run failure whose primary symptom is the stage execution
  itself — route to `sdaf-failure-triage`.

## Preconditions

Ask for the layer under test (HANA DB HA or SCS/ERS HA), OS family, evidence
type (live cluster, captured bundle, or prior test run), and any existing
`crm` / `pcs` output, QA reports, execution logs, or HCMT bundles. If cluster
state was already changed manually, preserve who changed what and when before
diagnosing anything else.

## Recipe

### Step 1 — classify the request before touching the cluster

Pick one lane:

1. **Live read-only diagnosis** — explain current cluster state from status,
   placement, and existing logs.
2. **Captured artefact review** — read an existing `offline_validation` bundle,
   QA report, or HCMT result without acting on the running cluster.
3. **Framework-run or disruptive validation** — route to
   `sdaf-quality-assurance`; the online functional tests stop resources, move
   groups, fence nodes, and crash processes.
4. **Topology/design** — route to `sdaf-ha-topology`.
5. **Stage/run failure** — route to `sdaf-failure-triage`.

### Step 2 — collect read-only evidence first

Use the evidence ladder in
[`references/cluster-evidence.md`](references/cluster-evidence.md). Minimum
safe evidence is:

- OS-specific status: `crm status full` on SUSE or `pcs status --full` on
  Red Hat;
- current placement evidence such as `crm_resource --locate` for SCS/ERS;
- existing fencing, SBD, or HANA hook-verification evidence;
- existing QA, offline `cib`, and HCMT artefacts.

Preserve raw output, host, and timestamp. Do not paraphrase away the cluster's
own wording.

### Step 3 — map the evidence to the right owner

- **Stay in this skill** for read-only interpretation of current Pacemaker
  state, placement, fencing/SBD evidence, hook traces, or existing QA/HCMT
  artefacts.
- **Route to `sdaf-quality-assurance`** to run configuration checks, offline HA
  validation from captured `offline_validation/<host>/cib` bundles, or
  disruptive online HA exercises in an approved maintenance window.
- **Route to `sdaf-failure-triage`** for failed SDAF runs or install-phase
  assertions such as missing fencing SPN details, cluster password, or
  required clustering scripts.
- **Route to `sdaf-ha-topology`** when the question is what the cluster
  *should* look like rather than what the current evidence says.

### Step 4 — stop before state changes

The current codebase contains state-changing cluster actions in validation and
post-provision tasks. This skill is **not** the place to run them.

The explicit stop-list lives in the reference. From this skill do **not**
execute `crm/pcs resource move`, `stonith_admin --cleanup`, role-defined
cluster cleanup, `StartService`, `StartSystem ALL`, or online functional HA
tests. If the user asks for recovery or failover action, stop at evidence
collection and routing; do not invent or approve a repair step.

## Hard rules

- Read-first only. Start with existing cluster status, logs, and artefacts.
- Documented/current-code only (D19). If the docs or shipped roles do not
  describe a diagnostic path, say so and stop.
- Do not invent recovery commands, failover steps, or cleanup procedures.
- Keep topology and design separate; route those questions to
  `sdaf-ha-topology`.
- Treat disruptive validation as a separate workflow owned by
  `sdaf-quality-assurance`.

## What this skill does NOT do

- Does not choose SBD vs Azure fence agent, storage, distro, ANGI, or
  scale-out design.
- Does not build, rebuild, reinstall, or actively fail over the cluster.
- Does not treat HCMT as the first diagnostic step; it only reuses existing
  HCMT artefacts if they are already present.

## See also

- `sdaf-ha-topology`
- `sdaf-quality-assurance`
- `sdaf-failure-triage`
- `docs/local/07-10-quality-assurance.md`
