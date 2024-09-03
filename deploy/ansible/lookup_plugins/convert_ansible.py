def setting_vars():
    this_sid = {
        'sid': sap_id.upper(),
        'dbsid_uid': hdbadm_uid,
        'sidadm_uid': asesidadm_uid if platform == 'SYSBASE' else sidadm_uid,
        'ascs_inst_no': scs_instance_number,
        'pas_inst_no': pas_instance_number,
        'app_inst_no': app_instance_number 
    }
    try: 
        all_sap_mounts =  multi_sids 
    except:
        all_sap_mounts = dict(**all_sap_mounts, **this_sid)

    for server in list_of_servers:
        first_server = query(sap_id.upper()+'_'+server)
        first_server_temp.append(first_server)

    afs_mnt_options = 'noresvport,vers=4,minorversion=1,sec=sys'

    print(this_sid)
    print(all_sap_mounts)
    print(first_server_temp)

def query(full_hostname):
    with open('/etc/ansible/hosts', 'r') as file:
        lines = file.readlines()
        for line in lines:
            if full_hostname in line: 
                return full_hostname

setting_vars()
