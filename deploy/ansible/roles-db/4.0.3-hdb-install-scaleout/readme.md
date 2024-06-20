# Task 4.0.3-HDB-install-scaleout

This task is part of the SAP Automation project and focuses on installing SAP HANA Database in a scale-out configuration using Ansible.
The supported configurations are
1. Scale out with Standby node. Requires HANA shared (single volume ), Data and log to be on an NFS4.1 compliant storage like ANF.
2. Scale out with two sites replicated via HSR and managed by Pacemaker.

## Prerequisites

Before running this task, make sure you have the following:

- Ansible installed on your system
- Access to the SAP HANA installation media
- A valid SAP HANA license key
- A properly configured inventory file for your SAP HANA scale-out landscape

For Scale out with Standby
- HANA hosts in single zone.
- Single HANA shared with access for all HANA hosts. Can be on AFS or ANF.
- Data volume on ANF, one volume for each HANA host.
- Log volume on ANF, one volume for each HANA host.
- (Optional) HANA backup on ANF/AFS.

For Scale out in HSR replication
- HANA hosts ( Even number count ) distributed across two zones.
- Two HANA shared volumes , one for each site. Can be AFS/ANF
- Premium SSD V1 histing Data and log volume , unique per host.
- (Optional) HANA backup on ANF/AFS.

The Bill of Material must have below lines in the DBLoad template
 - "hanadb.landscape.reorg.useCheckProcedureFile                          = DONOTUSEFILE"
-  "hanadb.landscape.reorg.useParameterFile                               = DONOTUSEFILE"


## Usage

To use this task, follow these steps:

1. Clone the SAP Automation repository to your local machine.
2. Navigate to the `ansible/roles-db/4.0.3-hdb-install-scaleout` directory.
3. Update the `inventory` file with the details of your SAP HANA scale-out landscape.
4. Modify the `group_vars` and `host_vars` files to match your specific requirements.
5. Run the Ansible playbook using the command `ansible-playbook site.yml`.

## Configuration

The configuration files for this task are located in the `ansible/roles-db/4.0.3-hdb-install-scaleout` directory. You can modify these files to customize the installation process according to your needs.

## License

This project is licensed under the [MIT License](LICENSE).
## Calling the Task

To call the task `4.0.3-HDB-install-scaleout` with the correct parameters, follow these steps:

1. Open the terminal or command prompt.
2. Navigate to the directory where the task code is located: `/D:/github/shsorot/sap-automation/deploy/ansible/roles-db/4.0.3-hdb-install-scaleout`.
3. Make sure you have Ansible installed on your system.
4. Ensure that you have access to the SAP HANA installation media and a valid SAP HANA license key.
5. Verify that you have a properly configured inventory file for your SAP HANA scale-out landscape.
6. Modify the `inventory` file in the task directory to include the details of your SAP HANA scale-out landscape.
7. Customize the `group_vars` and `host_vars` files in the task directory to match your specific requirements.
8. Run the Ansible playbook using the following command: `ansible-playbook site.yml`.

Make sure to replace `site.yml` with the actual name of the playbook file for the task.

Please note that the specific parameters and configuration files may vary depending on your setup and requirements.
