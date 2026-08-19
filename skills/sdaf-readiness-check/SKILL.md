---
name: sdaf-readiness-check
description: >
  Pre-flight an SDAF host, subscription, and configuration set BEFORE any
  deploy. Drives the shipped readiness helpers (`check_workstation.sh`,
  `Test-SDAFReadiness.ps1`, `Test-SDAFURLs.ps1`, `validate.sh`) as documented
  in `docs/local/02-00-prepare-execution-environment.md § Readiness
  verification`, and walks the documented "Before you begin" gates from
  `docs/local/01-00-prerequisites.md`. Use when a user says "pre-flight SDAF",
  "check SDAF readiness", "validate my tfvars", "am I ready to deploy the
  control plane", "run validate.sh", "run Test-SDAFReadiness", "check
  endpoints" or "check SDAF prerequisites". Do NOT use to actually deploy
  (see sdaf-control-plane-bootstrap / sdaf-workload-zone / sdaf-sap-system)
  or to triage a failed run (see sdaf-failure-triage).
allowed-tools: shell
license: MIT
---

# SDAF Readiness Check

Action-loop skill. Drives the shipped readiness helpers per the documented
`Readiness verification` subsection, and honours the documented pre-deploy
gates. Reports what was checked and what failed; refuses to invent checks the
docs and shipped scripts do not describe.

## When to invoke

Trigger on: "pre-flight", "readiness", "validate tfvars", "before I deploy",
"Test-SDAFReadiness", "Test-SDAFURLs", "validate.sh", "check endpoints",
"prerequisites for SDAF".

Do NOT trigger on: deploying a stage; installing SDAF; troubleshooting a run
that already failed (use `sdaf-failure-triage`).

## Preconditions

- The SDAF checkout is available (env `SAP_AUTOMATION_REPO_PATH`).
- The config workspace is available (env `CONFIG_REPO_PATH`).
- Target subscription is picked (env `ARM_SUBSCRIPTION_ID`).

If any of the three env vars is unset, stop and print
`docs/local/troubleshooting.md § A required export is missing`.

## Recipe

### Step 1 — Documented "Before you begin" gates

Walk the operator through the two doc-defined gates in this order:

- `docs/local/01-00-prerequisites.md § Before you begin`, `§ Pin versions`,
  `§ Plan identity and access`, `§ Review networking, DNS, and quota`,
  `§ Review configuration ownership`, `§ Review gate`.
- `docs/local/02-00-prepare-execution-environment.md § Before you begin`,
  `§ Prepare the host`, `§ Prepare configuration`,
  `§ Protect secrets and transient files`, `§ Review gate`.

Do NOT summarise the identity role set from memory; the docs point at the
identity-and-access section rather than restating the role set inline. Point
the operator at that section and stop.

### Step 2 — Run the documented readiness scripts

`docs/local/02-00-prepare-execution-environment.md § Readiness verification`
is the shipped procedure. Walk its four numbered steps in order:

1. `check_workstation.sh` — toolchain versions.
2. `Test-SDAFReadiness.ps1` — overall host readiness.
3. `Test-SDAFURLs.ps1` — outbound endpoint reachability.
4. `validate.sh` — per-workspace `.tfvars` sanity, once per workspace the
   operator plans to deploy.

Read the *shipped script's* output (and `Get-Help` for the PowerShell
scripts) as the authority on what each checks; do not narrate behaviour
beyond what the script prints. See
[`references/host-readiness.md`](references/host-readiness.md) for the
minimal notes needed to route failures.

Exit-code discipline for each invocation:

- `0` — the script signalled success. Read the output anyway; a printed
  warning is a real signal.
- non-zero — a failure or a validation-gate refusal. Do not claim the check
  passed. Route the failure by the section named in
  [`references/host-readiness.md`](references/host-readiness.md).

### Step 3 — Route any failure before deploying

If any of the four steps in the shipped `§ Readiness verification`
subsection reports a failure, do not proceed to deploy. Route via
`sdaf-failure-triage` if the failure symptom is ambiguous, or directly to
the doc anchor named in `references/host-readiness.md`.

## Hard rules

- **Do not** infer or reconstruct undocumented behaviour of any readiness
  script (D19). If the docs, `Get-Help`, or shipped script output are silent,
  say so and stop.
- **Do not** grant broad Azure roles "to bypass an error"
  (`docs/local/troubleshooting.md § Azure authentication or authorization fails`).
- **Do not** claim success without checking the shipped script's exit code.
- **Do not** replace the shipped scripts with an ad-hoc reimplementation.

## What this skill does NOT do

- Does not deploy anything.
- Does not rotate credentials, mint identities, or grant roles.
- Does not attempt to diagnose network paths beyond running the shipped URL
  check.
- Does not summarise identity-role sets from memory (docs point to code /
  the identity-and-access section).

## See also

- `sdaf-orientation-and-surface` — surface choice, prints install commands.
- `sdaf-workspace-and-tfvars` — the layout `validate.sh` presupposes.
- `sdaf-control-plane-bootstrap` — the first deploy step.
- `sdaf-failure-triage` — for a run that has already failed.
- `docs/local/01-00-prerequisites.md`,
  `docs/local/02-00-prepare-execution-environment.md § Readiness verification`,
  `docs/local/troubleshooting.md`.