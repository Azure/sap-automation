from ansible.module_utils.basic import AnsibleModule
def run_module():
    module_args = dict(
        nfs_server_temp=dict(type="str",required=True),
        NFS_provider=dict(type="str",required=True),
    )

    result = {
        "nfs_server_temp": [],
        "nfs_server": "",
    }

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    result['nfs_server_temp'].append(module.params['nfs_server_temp'])

    module.exit_json(**result)

if __name__ == "__main__":
    run_module()
