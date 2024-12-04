"""Settings Vars Module for SAP Mounts Oracle Role. This uses the AnsibleModule from the Ansible module_utils to set the parameters for the SAP mounts on Oracle.
"""
from ansible.module_utils.basic import AnsibleModule

def run_module():
    """ This function sets the parameters for the SAP mounts on Oracle.
        Input parameters are nfs_server and NFS_provider. 
        The output parameters are nfs_server_temp and nfs_server.
    """
    module_args = dict(
        nfs_server_temp=dict(type="str", required=True),
        NFS_provider=dict(type="str", required=True),
    )

    result = {
        "nfs_server_temp": [],
        "nfs_server": "",
    }

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    result["nfs_server_temp"].append(module.params["nfs_server_temp"])

    module.exit_json(**result)

if __name__ == "__main__":
    run_module()