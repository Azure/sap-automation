from ansible.module_utils.basic import AnsibleModule
def run_module():
    first_server_temp = []
    all_sap_mounts = {}
    module_args = dict(
        sap_sid=dict(type="str", required=True),
        hdbadm_uid=dict(type="str", required=True),
        platform=dict(type="str", required=True),
        sidadm_uid=dict(type="str", required=True),
        multi_sids=dict(type='list', required=False),
        asesidadm_uid=dict(type="str", required=False),
        scs_instance_number=dict(type="str", required=True),
        pas_instance_number=dict(type="str", required=True),
        app_instance_number=dict(type="str", required=True),
        server_name=dict(type="str", required=True),
    )
        
    result = {
        "this_sid": {},
        "all_sap_mounts": {},
        "first_server_temp": [],
        "mnt_options": {}
    }
    
    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    result['this_sid'] = {
        'sid': module.params['sap_sid'].upper(),
        'dbsid_uid': module.params['hdbadm_uid'],
        'sidadm_uid': module.params['asesidadm_uid'] if module.params['platform'] == 'SYSBASE' else module.params['sidadm_uid'],
        'ascs_inst_no': module.params['scs_instance_number'],
        'pas_inst_no': module.params['pas_instance_number'],
        'app_inst_no': module.params['app_instance_number'] 
    }
    try: 
        if module.params['multi_sids'] in locals():
            result['all_sap_mounts'] = module.params['multi_sids']
        
        else:
            result['all_sap_mounts'].update(result['this_sid'])

    except Exception as e:
        module.fail_json(msg=str(e),**result)

    result['first_server_temp'].append(module.params['server_name'])

    result['mnt_options'] = {
        'afs_mnt_options': 'noresvport,vers=4,minorversion=1,sec=sys',
        'anf_mnt_options': 'rw,nfsvers=4.1,hard,timeo=600,rsize=262144,wsize=262144,noatime,lock,_netdev,sec=sys'
    }

    module.exit_json(**result)

if __name__ == "__main__":
    run_module()
