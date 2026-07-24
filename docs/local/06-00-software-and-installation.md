# Download software and install SAP locally

## Outcome

The approved SAP software is available in the SAP library, and the selected
operating-system, database, high-availability, and SAP installation playbooks
have completed against the generated inventory.

## Before you begin

- Complete [SAP-system infrastructure deployment](05-00-sap-system.md).
- Confirm `sap-parameters.yaml` and `<SID>_hosts.yaml` exist in the system
  directory.
- Confirm SSH connectivity from the execution host to every inventory host.
- Confirm the workload-zone Key Vault contains the generated credentials.
- Confirm the SAP library has sufficient capacity.
- Confirm SAP licenses and download credentials.
- Back up the system and obtain a maintenance window before rerunning
  installation playbooks on an existing system.

## Inputs and BOM ownership

Define `<SAP_SYSTEM>` as the same-named system directory and `.tfvars` base
name. Define `<ABSOLUTE_PATH_TO_SAP_AUTOMATION_SAMPLES>` as the absolute path
to the reviewed samples checkout.

The
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples)
repository owns the `SAP` application definitions and `BOM` files.

Set `BOM_CATALOG` to the root of a reviewed samples checkout that contains
the `SAP/` and `BOM/` directories:

```bash
export BOM_CATALOG="<ABSOLUTE_PATH_TO_SAP_AUTOMATION_SAMPLES>"
```

`download_menu.sh` passes this value to Ansible as `BOM_directory`. The BOM
utility searches below that root, including:

- `SAP/<name>/<name>.yaml`
- `BOM/<name>/<name>.yaml`
- `archives/<name>/<name>.yaml`

Do not set `BOM_CATALOG` to an individual BOM directory.

The Terraform-generated `sap-parameters.yaml` contains `bom_base_name`, but
`download_menu.sh` does not preserve that value. The wrapper instead requires
these component keys:

- `application_bom_name`
- `database_bom_name`
- `sap_kernel_bom_name`
- `save_bom_as`

Before using the download menu, add reviewed values for all four keys to
`sap-parameters.yaml`:

```yaml
application_bom_name: <APPLICATION_BOM>
database_bom_name: <DATABASE_BOM>
sap_kernel_bom_name: <KERNEL_BOM>
save_bom_as: <COMBINED_BOM_NAME>
```

The wrapper combines the four values and passes the result to
[`playbook_bom_downloader.yaml`](../../deploy/ansible/playbook_bom_downloader.yaml).
Without these keys, it overrides the generated BOM value with an invalid empty
combination. Keep these values unquoted because the wrapper extracts the second
whitespace-delimited field instead of parsing YAML.

## Configuration preparation

1. Review the application, database, and kernel BOMs in the samples checkout.
2. Review all SAP download URLs, archive names, checksums, and target product
   versions.
3. Review `sap-parameters.yaml`, especially the BOM names, SAP SID, database
   SID, Key Vault name, secret prefix, and installation options.
4. Review `<SID>_hosts.yaml` for expected hosts and groups.
5. Record approval of the software versions and installation scope.

## What the automation does

[`download_menu.sh`](../../deploy/ansible/download_menu.sh):

- Requires `sap-parameters.yaml` in the current directory.
- Requires `BOM_CATALOG` to identify the samples root.
- Runs the BOM downloader playbook interactively.
- Downloads and stages software according to the selected BOM definitions.

[`configuration_menu.sh`](../../deploy/ansible/configuration_menu.sh):

- Requires `sap-parameters.yaml` in the current directory.
- Derives the inventory name from `sap_sid`.
- Retrieves the system password from the workload-zone Key Vault.
- Retrieves the SAP system SSH key from the workload-zone Key Vault through
  `pb_get-sshkey.yaml`.
- Runs selected numbered playbooks.
- Runs customer pre- and post-playbooks from
  `$CONFIG_REPO_PATH/ANSIBLE` when matching files exist.
- Reports customer hook failures but continues to the numbered playbook or the
  next selected playbook.
- Stops the selected sequence after a failed numbered playbook.

The menu exposes validation, OS configuration, SAP OS configuration, BOM
processing, SCS, database, database load, database HA, PAS, application
server, Web Dispatcher, ACSS, AMS, HCMT, post-installation, and grouped
selections.

## Review before execution

Review SAP license terms, download destinations, credentials, disk capacity,
inventory targets, playbook selection, maintenance windows, and custom
pre/post playbooks.

> [!WARNING]
> Installation playbooks change operating systems, storage, clusters,
> databases, and SAP instances. Do not select **All Playbooks** on an existing
> system without reviewing idempotence, progress markers, and recovery for
> every included playbook.

## Download software

1. Change to the SAP-system directory.

   ```bash
   cd "$CONFIG_REPO_PATH/WORKSPACES/SYSTEM/<SAP_SYSTEM>"
   ```

2. Confirm the BOM catalog root.

   ```bash
   test -d "$BOM_CATALOG/SAP"
   test -d "$BOM_CATALOG/BOM"
   ```

   Both commands return successfully.

3. Start the download menu.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/ansible/download_menu.sh"
   ```

4. Select **BOM Downloader**.

   The playbook reports each selected archive and download result.

## Run configuration and installation

1. Start the configuration menu from the same system directory.

   ```bash
   "$SAP_AUTOMATION_REPO_PATH/deploy/ansible/configuration_menu.sh"
   ```

2. Select **Validate parameters** first.

   The validation playbook confirms required parameters and host reachability.

3. Select one reviewed playbook or grouped sequence.

   The wrapper reports the current playbook and stops if a numbered playbook
   returns a nonzero status. Customer pre- and post-playbook failures are
   reported but do not stop the sequence.

4. After the menu exits, remove the retrieved private-key file immediately.

   ```bash
   rm -f -- "$PWD/sshkey"
   test ! -e "$PWD/sshkey"
   ```

   The wrapper removes `sshkey` only when **Quit** is selected. A normal
   playbook selection exits without removing it, including after a failed
   numbered playbook.

5. Repeat steps 1 through 4 for the next approved sequence.

   Progress files under the workspace `.progress` directory provide evidence
   for BOM and installation stages that implement markers.

## Validate

1. Confirm that the downloader reports success for every required archive.
2. Confirm that the SAP library contains the expected software.
3. Confirm that each selected playbook reports successful completion.
4. Confirm expected `.progress` markers on the target workspace.
5. Confirm operating-system, database, cluster, and SAP service health using
   the product-specific operational checks.
6. Retain Ansible console output and relevant target logs with the deployment
   record.

## Safe retry

Correct the failed prerequisite or task, then rerun the smallest applicable
playbook. Before restarting a grouped sequence, identify any failed numbered
playbook or customer hook and review its output, progress marker, and
idempotence. A failed pre-hook does not prevent the numbered playbook from
running, and a failed post-hook does not stop the next selected playbook.

Do not delete `.progress` markers merely to force a rerun. Review the role that
owns the marker and the target system state first.

## Next step

[Operate, recover, and remove the deployment](07-00-operations.md).
