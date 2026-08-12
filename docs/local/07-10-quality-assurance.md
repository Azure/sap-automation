# Validate a local deployment with quality assurance tests

## Outcome

You have run the SAP quality assurance framework against a deployed SAP
system from your local execution host, and you have a report and an execution
log that record which checks and test cases passed.

## Before you begin

Complete [Download software and run installation](06-00-software-and-installation.md)
so that the SAP system is installed and running. Quality assurance validates a
configured system. It does not install one.

Confirm the following:

- The SAP-system directory contains `sap-parameters.yaml` and the generated
  `<SAP_SID>_hosts.yaml` inventory.
- You are signed in to Azure with `az login` and can read the workload-zone
  Key Vault that holds the SAP-system SSH key and password.
- The execution host can reach every host in the inventory over SSH.
- The execution host can reach `https://github.com`. The setup role clones and
  updates the quality assurance framework on every run, so it contacts the
  remote even when the framework is already present locally.
- You have `sudo` rights on the execution host. The wrapper installs the
  framework and its Python dependencies under `/opt/microsoft`.
- `ARM_CLIENT_ID` identifies the managed identity to use when the execution
  host has more than one assigned identity. The control-plane deployer sets
  this variable in `/etc/profile.d/deploy_server.sh`. On any other host,
  export it before you start the wrapper.

> [!NOTE]
> The quality assurance framework signs in with the managed identity of the
> execution host before it runs any check. On a host with several assigned
> identities, that sign-in fails unless `ARM_CLIENT_ID` names the identity to
> use. The framework replaces the current Azure CLI session when it signs in.

> [!WARNING]
> High availability functional tests deliberately disrupt a running system.
> They stop resources, move cluster groups, fence nodes, and crash processes.
> Run them only against a system where that disruption is approved, and only
> inside an agreed maintenance window.

## Inputs

For a quality assurance run, identify:

- `<SAP_SYSTEM>`: Same-named SAP-system directory under
  `$CONFIG_REPO_PATH/WORKSPACES/SYSTEM`.
- `<SAP_SID>`: The `sap_sid` value in `sap-parameters.yaml`. It determines the
  inventory file name.
- The test type: configuration checks or SAP functional tests.
- For functional tests, the functional test type: database high availability,
  central services high availability, or Azure Backup database.
- Optional `TEST_GROUPS` and `TEST_CASES` values to narrow the run.
- `ARM_CLIENT_ID`: Client ID of the managed identity that the framework signs
  in with.
- The approved maintenance window and the approver for a disruptive test.

## What the automation does

[`quality_assurance_menu.sh`](../../deploy/ansible/quality_assurance_menu.sh):

- Requires `sap-parameters.yaml` in the current directory.
- Reads `sap_sid`, `kv_name`, and `secret_prefix` from that file.
- Retrieves the SAP system password and, through
  [`pb_get-sshkey.yaml`](../../deploy/ansible/pb_get-sshkey.yaml), the SSH key
  from the workload-zone Key Vault.
- Passes `ARM_CLIENT_ID` to the framework as
  `user_assigned_identity_client_id` when that variable is set.
- Runs
  [`playbook_06_03_00_sap_functional_tests.yaml`](../../deploy/ansible/playbook_06_03_00_sap_functional_tests.yaml),
  which clones
  [`Azure/sap-automation-qa`](https://github.com/Azure/sap-automation-qa) at
  the pinned version, installs its Ansible collections and Python
  dependencies, resolves the requested test groups and cases, and writes the
  resolved selection to `artifacts/qa_test_selection.json`.
- Runs the matching quality assurance playbook from the framework against the
  SAP-system inventory.
- Removes the retrieved private-key file when the run finishes.

The framework writes results under the SAP-system directory:

- `quality_assurance/` contains the HTML report,
  `<test_group_name>_<test_group_invocation_id>.html`.
- `logs/<test_group_invocation_id>.log` contains the machine-readable JSONL
  results that the report is rendered from.
- `logs/execution_<timestamp>.log` contains the Ansible execution log that the
  report embeds.

Retain the `logs/` files alongside the report. The JSONL results are the only
machine-readable record of the run.

The menu selection maps to a framework playbook as follows:

| Menu selection | Test type | Framework playbook |
| --- | --- | --- |
| Configuration checks | `ConfigurationChecks` | `playbook_00_configuration_checks.yml` |
| Database high availability functional tests | `SAPFunctionalTests` | `playbook_00_ha_db_functional_tests.yml` |
| Central services high availability functional tests | `SAPFunctionalTests` | `playbook_00_ha_scs_functional_tests.yml` |
| Azure Backup database functional tests | `SAPFunctionalTests` | `playbook_00_backup_db_functional_tests.yml` |
| Database high availability offline tests | `SAPFunctionalTests` | `playbook_01_ha_offline_tests.yml` |
| Central services high availability offline tests | `SAPFunctionalTests` | `playbook_01_ha_offline_tests.yml` |

## Review before execution

Review the following before you start a run:

- Whether the selected test type disrupts the system. Configuration checks are
  read-only, and the offline high availability tests validate captured cluster
  configuration rather than the running cluster. The online functional tests
  act on the running system and are disruptive.
- The maintenance window, the approver, and the rollback expectation for a
  disrupted cluster.
- The inventory scope. Functional tests act on the cluster nodes in
  `<SAP_SID>_hosts.yaml`.
- Whether the framework version pinned in
  [`ansible-input-api.yaml`](../../deploy/ansible/vars/ansible-input-api.yaml)
  is the version you intend to run.
- Whether the run writes telemetry. Telemetry destination and workspace values
  come from the framework defaults unless you override them.

## Run quality assurance

1. Change to the SAP-system directory.

   ```bash
   cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
   ```

2. Confirm the parameter file and inventory are present.

   ```bash
   test -f sap-parameters.yaml
   test -f "<SAP_SID>_hosts.yaml"
   ```

   Both commands return successfully.

3. Start the quality assurance menu.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/ansible/quality_assurance_menu.sh"
   ```

4. Select **Configuration checks** for the first run.

   The wrapper reports the prepared run, then executes the configuration
   checks against every host in the inventory.

5. Review the report before you select a functional test.

   ```bash
   ls -1 quality_assurance/
   ```

   The directory contains an HTML report for the completed run.

6. To narrow a functional test, export the selection before you start the
   menu.

   ```bash
   TEST_GROUPS="HA_SCS" \
   TEST_CASES="ascs-migration" \
   "$SAP_AUTOMATION_REPO_PATH/deploy/ansible/quality_assurance_menu.sh"
   ```

   `TEST_GROUPS` takes a single exact group name, such as `HA_DB_HANA`,
   `HA_SCS` or `BACKUP_DB_HANA`. `TEST_CASES` takes a comma-separated list of
   `task_name` values, such as `ascs-migration`, `resource-migration`,
   `primary-node-crash` or `block-network`. The framework matches `task_name`,
   not the display name, so `Manual ASCS Migration` is not a valid value. The
   authoritative list is `src/vars/input-api.yaml` in the pinned framework.

   Always set `TEST_GROUPS` when you set `TEST_CASES`. A case-only selection is
   resolved across every group, so it can enable a case that the playbook for
   the selected functional test type never reads, producing a run with no
   executed cases.

   The preparation playbook fails with the resolved selection when a group or
   case name does not match the framework version in use.

7. Select the functional test that matches the approved maintenance activity.

   The wrapper reports the executing playbook and the results directory.

## Validate

1. Confirm the wrapper reports that the playbook completed successfully.
2. Confirm `quality_assurance/` contains an HTML report for the run.
3. Open the report and confirm it lists the expected test cases with a result
   for each. A report that states `No test results found.` means the framework
   produced no results log, not that every check passed.
4. Confirm `logs/` contains the execution log named in the completion banner.
5. For a functional test, confirm the cluster returned to its expected state
   before you close the maintenance window.
6. Retain the report, the results log, and the execution log with the
   deployment record.

## If it fails

Start with the execution log named in the failure banner, under `logs/` in the
SAP-system directory.

| Symptom | First check |
| --- | --- |
| The wrapper exits before any playbook runs | `sap_sid`, `kv_name`, and `secret_prefix` are present in `sap-parameters.yaml`, and `az account show` succeeds |
| Preparation fails while cloning the framework | Outbound access to `https://github.com` from the execution host |
| The framework reports `Multiple user assigned identities exist` | `ARM_CLIENT_ID` is exported and names an identity assigned to the execution host |
| Preparation fails on the resolved selection | The `TEST_GROUPS` and `TEST_CASES` names against `src/vars/input-api.yaml` in the pinned framework version |
| Hosts are unreachable | Inventory addresses, SSH access from the execution host, and whether the key was retrieved |
| The report contains no results | The execution log for a failed telemetry task, which the framework does not treat as fatal |

Correct the reported condition and rerun the same selection. Configuration
checks are safe to repeat. Before you repeat a functional test, confirm the
cluster is healthy and the maintenance window still applies.

## Next step

Return to [Operate, recover, and remove a local deployment](07-00-operations.md)
for update, recovery, and removal procedures, or use
[Troubleshoot local execution](troubleshooting.md) when a run stops
unexpectedly.
