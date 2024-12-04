"""Settings Vars Module for SAP Mounts Role. This uses the AnsibleModule from the Ansible module_utils to set the parameters for the SAP mounts.
"""
from ansible.module_utils.basic import AnsibleModule

def run_module():
    """This function sets the parameters for the SAP mounts.
        Input parameters are the SAP SID, HDBADM UID, platform, SIDADM UID, multi SIDs, asesidadm_uid(not required), SCS instance number, PAS instance number, APP instance number, server name and distribution full ID(not required). 
        The output parameters are the SID, all_sap_mounts, first_server_temp, mnt_options and nfs_service.
    """
    distro_versions = [
        "redhat8.4",
        "redhat8.6",
        "redhat8.8",
        "redhat9.0",
        "redhat9.2",
        "sles_sap15.2",
        "sles_sap15.3",
        "sles_sap15.4",
        "sles_sap15.5",
        "sles_sap15.4",  # sles stands for SUSE Linux Enterprise Server
        "sles_sap15.5",
        ]
    
    module_args = dict(
        sap_sid=dict(type="str", required=True),
        hdbadm_uid=dict(type="str", required=True),
        platform=dict(type="str", required=True),
        sidadm_uid=dict(type="str", required=True),
        multi_sids=dict(type="list", required=False),
        asesidadm_uid=dict(type="str", required=False),
        scs_instance_number=dict(type="str", required=True),
        pas_instance_number=dict(type="str", required=True),
        app_instance_number=dict(type="str", required=True),
        server_name=dict(type="str", required=True),
        distribution_full_id=dict(type="str", required=False),
        distribution_id=dict(type="str", required=False),
    )

    result = {
    "this_sid": {},
    "all_sap_mounts": [],
    "first_server_temp": [],
    "mnt_options": {},
    "nfs_service": "",
    }

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    distribution_id = module.params["distribution_id"]

    distribution_full_id = module.params["distribution_full_id"]

    result["this_sid"] = {
        "sid": module.params["sap_sid"].upper(),
        "dbsid_uid": module.params["hdbadm_uid"],
        "sidadm_uid": (
            module.params["asesidadm_uid"]
            if module.params["platform"] == "SYSBASE"
            else module.params["sidadm_uid"]
        ),
        "ascs_inst_no": module.params["scs_instance_number"],
        "pas_inst_no": module.params["pas_instance_number"],
        "app_inst_no": module.params["app_instance_number"],
    }

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    result["this_sid"] = {
        "sid": module.params["sap_sid"].upper(),
        "dbsid_uid": module.params["hdbadm_uid"],
        "sidadm_uid": (
            module.params["asesidadm_uid"]
            if module.params["platform"] == "SYSBASE"
            else module.params["sidadm_uid"]
        ),
        "ascs_inst_no": module.params["scs_instance_number"],
        "pas_inst_no": module.params["pas_instance_number"],
        "app_inst_no": module.params["app_instance_number"],
    }
    try:
        if module.params["multi_sids"] is not None:
            result["all_sap_mounts"] = module.params["multi_sids"]

        else:
            result["all_sap_mounts"].append(result["this_sid"])

    except Exception as e:
        module.fail_json(msg=str(e), **result)

    result["first_server_temp"].append(module.params["server_name"])

    result["mnt_options"] = {
        "afs_mnt_options": "noresvport,vers=4,minorversion=1,sec=sys",
        "anf_mnt_options": "rw,nfsvers=4.1,hard,timeo=600,rsize=262144,wsize=262144,noatime,lock,_netdev,sec=sys" + (",nconnect=8" if distribution_full_id in distro_versions else ""),
    }

    nfs_service_mapping = {
        "redhat8": "nfs-server",
        "redhat9": "nfs-server",
        "redhat7": "nfs",
        "oraclelinux8": "rpcbind",
    }
    result["nfs_service"] = nfs_service_mapping.get(distribution_id.split('.')[0], "nfs-server")

    module.exit_json(**result)

if __name__ == "__main__":
    run_module()