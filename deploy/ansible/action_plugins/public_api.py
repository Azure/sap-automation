#!/usr/bin/env python3.9
from __future__ import absolute_import, division, print_function

__metaclass__ = type

import json
import os
import tempfile
import requests
from cryptography.fernet import Fernet
from azure.common.exceptions import AuthenticationError
from msrest.exceptions import ClientRequestError
from azure.common.credentials import ServicePrincipalCredentials
from azure.keyvault import KeyVaultClient
from ansible.errors import AnsibleConnectionFailure, AnsibleActionFail
from ansible.utils.display import Display
from ansible.module_utils.urls import Request, ConnectionError
from six.moves.urllib.error import HTTPError, URLError
from ansible.plugins.action import ActionBase

method_spec_product = dict(
    method=dict(type="str", required=True),
    calKeyvaultId=dict(type="str", required=True, no_log=True),
    clientId=dict(type="str", no_log=True),
    clientSecret=dict(type="str", no_log=True),
)
method_spec_progress = dict(
    method=dict(type="str", required=True),
    calKeyvaultId=dict(type="str", required=True, no_log=True),
    clientId=dict(type="str", no_log=True),
    clientSecret=dict(type="str", no_log=True),
    systemId=dict(type="str", required=True),
    outputDirectoryPath=dict(type="str", no_log=True),
    outputFile=dict(type="str", no_log=True),
)
method_spec_deployment = dict(
    method=dict(type="str", required=True),
    outputDirectoryPath=dict(type="str", no_log=True),
    outputFile=dict(type="str", no_log=True),
    calKeyvaultId=dict(type="str", required=True, no_log=True),
    clientId=dict(type="str", no_log=True),
    clientSecret=dict(type="str", no_log=True),
    tenantId=dict(type="str", no_log=True),
    accountId=dict(type="str", required=True, no_log=True),
    productId=dict(type="str", required=True, no_log=True),
    cloudProvider=dict(type="str", required=True),
    planTemplateId=dict(type="str", required=True, no_log=True),
    planTemplateName=dict(type="str", required=True, no_log=True),
    region=dict(type="str", default="eastus2"),
    availabilityScenario=dict(
        type="str",
        choices=["non-ha", "hana-system-replication", "clustering"],
        default="clustering",
    ),
    infrastructureParameterSet=dict(
        type="dict",
        required=True,
        options=dict(
            operatingSystem=dict(
                type="str", default="SUSE/sles-sap-15-sp3/gen1/2022.11.09"
            ),
            privateDnsZone=dict(type="str", required=True),
            reversePrivateDnsZone=dict(type="str", required=True, no_log=True),
            transitNetwork=dict(type="str", required=True, no_log=True),
            workloadNetwork=dict(type="str", required=True, no_log=True),
            sharedServicesNetwork=dict(type="str", required=True, no_log=True),
            sharedServicesSubnet=dict(type="str", required=True, no_log=True),
            workloadNetworkHanaSubnet=dict(type="str", required=True, no_log=True),
            workloadNetworkAsSubnet=dict(type="str", required=True, no_log=True),
            technicalCommunicationUser=dict(type="str", required=True, no_log=True),
            techUserPassword=dict(type="str", required=True, no_log=True),
            maintenancePlannerTransaction=dict(type="str", required=True, no_log=True),
            hanaVmSize=dict(type="str", required=False, default="Standard_E20ds_v5"),
            centralServicesVmSize=dict(
                type="str", required=False, default="Standard_D4ds_v5"
            ),
            enqueueReplicationServerVmSize=dict(
                type="str", required=False, default="Standard_D4ds_v5"
            ),
            applicationServerVmSize=dict(
                type="str", required=False, default="Standard_E4ds_v5"
            ),
            numberOfApplicationServers=dict(type="int", required=False, default="0"),
            webDispatcherVmSize=dict(
                type="str", required=False, default="Standard_D2s_v5"
            ),
        ),
    ),
    installationParameterSets=dict(
        type="dict",
        required=True,
        apply_defaults=True,
        options=dict(
            clientId=dict(
                type="str",
                required_if=[("availabilityScenario", "==", "clustering")],
                no_log=True,
            ),
            clientSecret=dict(
                type="str",
                required_if=[("availabilityScenario", "==", "clustering")],
                no_log=True,
            ),
            hanaDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    DBSID=dict(type="str", default="HDB"),
                    DBSIDAdminUserId=dict(type="str", default="1050"),
                    instanceNumber=dict(type="str", default="00"),
                    frontendHostname=dict(type="str", default="vhdbdb"),
                    primaryHanaPhysicalHostname=dict(type="str", default="phdbdbpr"),
                    primaryHanaVirtualHostname=dict(type="str", default="vhdbdbpr"),
                    secondaryHanaPhysicalHostname=dict(type="str", default="phdbdbsr"),
                    secondaryHanaVirtualHostname=dict(type="str", default="vhdbdbsr"),
                ),
            ),
            s4hanaDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    SID=dict(type="str", default="S4H"),
                    SAPSysAdminUserId=dict(type="str", default="1079"),
                    SAPSysAdminGroupId=dict(type="str", default="79"),
                    sapGuiDefaultLanguage=dict(type="str", default="en"),
                    SAPSystemAdditionalLanguages=dict(type="str", default=""),
                    numberOfDialogWorkProcesses=dict(type="int", default="10"),
                    numberOfBatchWorkProcesses=dict(type="int", default="7"),
                ),
            ),
            centralServicesDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    instanceNumber=dict(type="str", default="00"),
                    ABAPMessageServerPort=dict(type="str", default="3600"),
                    physicalHostname=dict(type="str", default="ps4hcs"),
                    virtualHostname=dict(type="str", default="vs4hcs"),
                ),
            ),
            enqueueReplicationServerDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    instanceNumber=dict(type="str", default="10"),
                    physicalHostname=dict(type="str", default="ps4hers"),
                    virtualHostname=dict(type="str", default="vs4hers"),
                ),
            ),
            primaryApplicationServerDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    instanceNumber=dict(type="str", default="00"),
                    physicalHostname=dict(type="str", default="ps4hpas"),
                    virtualHostname=dict(type="str", default="vs4hpas"),
                ),
            ),
            additionalApplicationServersDeployment=dict(
                type="list",
                elements="dict",
                apply_defaults=True,
                options=dict(
                    instanceNumber=dict(type="str", default="00"),
                    physicalHostname=dict(type="str", default="ps4haas1"),
                    virtualHostname=dict(type="str", default="vs4haas1"),
                ),
            ),
            webDispatcherDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    installationType=dict(
                        type="str",
                        choices=["Standalone", "Embedded", "None", "External"],
                        default="None",
                    ),
                    primaryInstanceNumber=dict(type="str", default="00"),
                    primaryPhysicalHostname=dict(ype="str", default="ps4hwdpr"),
                    primaryVirtualHostname=dict(type="str", default="vs4hwdpr"),
                    secondaryInstanceNumber=dict(type="str", default="00"),
                    secondaryPhysicalHostname=dict(type="str", default="ps4hwdsr"),
                    secondaryVirtualHostname=dict(type="str", default="vs4hwdsr"),
                    userIdOfSIDAdmin=dict(type="str", default="1080"),
                    virtualHostname=dict(type="str", default="vs4hwdext"),
                    fioriHostname=dict(type="str", default="vs4hwdext"),
                    fioriHostPort=dict(type="int", default="44300"),
                    productiveClientNumber=dict(type="str", default="500"),
                ),
            ),
        ),
    ),
)
method_spec_provisioning = dict(
    method=dict(type="str", required=True),
    outputDirectoryPath=dict(type="str", no_log=True),
    outputFile=dict(type="str", no_log=True),
    productId=dict(type="str", required=True, no_log=True),
    planTemplateId=dict(type="str", no_log=True, default="default"),
    availabilityScenario=dict(
        type="str",
        choices=["non-ha", "hana-system-replication", "clustering"],
        default="clustering",
    ),
    calKeyvaultId=dict(type="str", required=True, no_log=True),
    clientId=dict(type="str", no_log=True),
    clientSecret=dict(type="str", no_log=True),
    tenantId=dict(type="str", no_log=True),
    infrastructureParameterSet=dict(
        type="dict",
        required=True,
        required_one_of=[
            ["domainName", "privateDnsZone"],
            ["techUserPassword", "techUserPasswordReference"],
        ],
        mutually_exclusive=[
            ["domainName", "privateDnsZone"],
            ["techUserPassword", "techUserPasswordReference"],
        ],
        options=dict(
            privateDnsZone=dict(type="str", no_log=True),
            domainName=dict(type="str", no_log=True),
            secretStoreId=dict(type="str", required=True, no_log=True),
            deploymentServerSubnet=dict(type="str", no_log=True),
            executionEngineSubnet=dict(type="str", no_log=True),
            technicalCommunicationUser=dict(type="str", required=True, no_log=True),
            techUserPassword=dict(type="str", no_log=True, default=""),
            techUserPasswordReference=dict(type="str", no_log=True),
            remoteOsUser=dict(type="str", required=True, no_log=True),
            deploymentServerResourceGroup=dict(type="str", required=False, no_log=True),
            sshPublicKeySecretName=dict(type="str", required=True, no_log=True),
            sshPrivateKeySecretName=dict(type="str", required=True, no_log=True),
            parameters=dict(type="str", no_log=True),
        ),
    ),
    installationParameterSets=dict(
        type="dict",
        required=True,
        apply_defaults=True,
        options=dict(
            hanaDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    primaryVmResourceId=dict(type="str", required=True),
                    secondaryVmResourceId=dict(type="str", default=""),
                    loadBalancerResourceId=dict(type="str", default=""),
                    frontEndIp=dict(type="str", default=""),
                    DBSID=dict(type="str", default="HDB"),
                    DBSIDAdminUserId=dict(type="str", default="1050"),
                    instanceNumber=dict(type="str", default="00"),
                    frontendHostname=dict(type="str", default=""),
                    primaryPhysicalHostname=dict(type="str", default=""),
                    primaryVirtualHostname=dict(type="str", default=""),
                    secondaryPhysicalHostname=dict(type="str", default=""),
                    secondaryVirtualHostname=dict(type="str", default=""),
                ),
            ),
            s4hanaDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    SID=dict(type="str", default="S4H"),
                    SAPSysAdminUserId=dict(type="str", default="1079"),
                    SAPSysAdminGroupId=dict(type="str", default="79"),
                    sapGuiDefaultLanguage=dict(type="str", default="en"),
                    SAPSystemAdditionalLanguages=dict(type="str", default=""),
                    numberOfDialogWorkProcesses=dict(type="str", default="10"),
                    numberOfBatchWorkProcesses=dict(type="str", default="7"),
                ),
            ),
            centralServicesDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    vmResourceId=dict(type="str", required=True),
                    loadBalancerResourceId=dict(type="str", default=""),
                    frontEndIp=dict(type="str", default=""),
                    instanceNumber=dict(type="str", default="00"),
                    ABAPMessageServerPort=dict(type="str", default=""),
                    physicalHostname=dict(type="str", default=""),
                    virtualHostname=dict(type="str", default=""),
                    loadBalancerHostname=dict(
                        type="str",
                        required_if=[("availabilityScenario", "==", "clustering")],
                    ),
                ),
            ),
            enqueueReplicationServerDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    vmResourceId=dict(type="str", default=""),
                    frontEndIp=dict(type="str", default=""),
                    instanceNumber=dict(type="str", default="10"),
                    physicalHostname=dict(type="str", default=""),
                    virtualHostname=dict(type="str", default=""),
                    loadBalancerHostname=dict(type="str"),
                ),
            ),
            applicationServersDeployment=dict(
                type="list",
                elements="dict",
                apply_defaults=True,
                options=dict(
                    vmResourceId=dict(type="str", default=""),
                    instanceNumber=dict(type="str", default="00"),
                    physicalHostname=dict(type="str", default=""),
                    virtualHostname=dict(type="str", default=""),
                ),
            ),
            fioriConfiguration=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    fioriHostname=dict(type="str", default=""),
                    fioriHostPort=dict(type="str", default="44300"),
                    productiveClientNumber=dict(type="str", default="500"),
                    ossUser=dict(type="str", default=""),
                    ossUserPassword=dict(type="str", default=""),
                    ossUserPasswordReference=dict(type="str", default=""),
                ),
            ),
            webDispatcherDeployment=dict(
                type="dict",
                apply_defaults=True,
                options=dict(
                    installationType=dict(
                        type="str",
                        choices=["Standalone", "Embedded", "None", "External"],
                        default="None",
                    ),
                    virtualHostname=dict(type="str", default=""),
                    primaryVmResourceId=dict(type="str", default=""),
                    primaryInstanceNumber=dict(type="str", default="00"),
                    primaryPhysicalHostname=dict(type="str", default=""),
                    primaryVirtualHostname=dict(type="str", default=""),
                    userIdOfSIDAdmin=dict(type="str", default="1080"),
                    secondaryVmResourceId=dict(type="str", default=""),
                    loadBalancerResourceId=dict(type="str", default=""),
                    frontEndIp=dict(type="str", default=""),
                    secondaryInstanceNumber=dict(type="str", default="00"),
                    secondaryPhysicalHostname=dict(type="str", default=""),
                    secondaryVirtualHostname=dict(type="str", default=""),
                ),
            ),
        ),
    ),
)

required_together = [["clientId", "clientSecret", "tenantId"]]

# Generate a key for encryption/decryption
FERNET_KEY = os.environ.get("FERNET_KEY", Fernet.generate_key().decode())
fernet = Fernet(FERNET_KEY.encode())


class SAPsystem:
    def __init__(self, params):
        self.input_params = params
        method = params.get("method")
        scenario = params.get("availabilityScenario")
        self.infrastructureParameterSet = params.get("infrastructureParameterSet")
        self.installationParameterSets = params.get("installationParameterSets")
        webdisp_type = self.installationParameterSets.get(
            "webDispatcherDeployment"
        ).get("installationType")
        if method == "deployment":
            self.props = self.get_nonha_deployment_params()
            if scenario == "hana-system-replication":
                self.props.get("installationParameterSets").update(
                    self.get_ha_deployment_params()
                )
            elif scenario == "clustering":
                self.props.get("installationParameterSets").update(
                    self.get_ha_deployment_params()
                )
                self.props.get("installationParameterSets").update(
                    self.get_cluster_deployment_params()
                )
            if webdisp_type != "No":
                if webdisp_type == "Standalone":
                    self.props["installationParameterSets"]["webDispatcherDeployment"][
                        "parameters"
                    ] += self.get_webdisp_deployment_standalone_params().get(
                        "parameters"
                    )
                    self.props["installationParameterSets"]["webDispatcherDeployment"][
                        "parameters"
                    ] += self.get_webdisp_deployment_params().get("parameters")
                    if scenario != "NON_HA":
                        self.props["installationParameterSets"][
                            "webDispatcherDeployment"
                        ]["parameters"] += self.get_webdisp_ha_deployment_params().get(
                            "parameters"
                        )
                else:
                    self.props["installationParameterSets"]["webDispatcherDeployment"][
                        "parameters"
                    ] += self.get_webdisp_deployment_params().get("parameters")
        elif method == "software_provisioning":
            self.props = self.get_nonha_provisioning_params()
            if scenario == "hana-system-replication":
                self.props.get("deploymentParameterSets").update(
                    self.get_ha_provisioning_params()
                )
            elif scenario == "clustering":
                self.props.get("deploymentParameterSets").update(
                    self.get_ha_provisioning_params()
                )

    def clean_parameters(self, parameters):
        # Filter out parameter dictionaries with value == "" or missing 'value' key
        return [param for param in parameters if param.get("value") not in [None, ""]]

    def clean_structure(self, structure):
        # Apply cleaning to the structure recursively
        if isinstance(structure, dict):
            cleaned_structure = {}
            for k, v in structure.items():
                if k == "parameters" and isinstance(v, list):
                    cleaned_structure[k] = self.clean_parameters(v)
                else:
                    cleaned_structure[k] = self.clean_structure(v)
            return cleaned_structure
        elif isinstance(structure, list):
            return [self.clean_structure(item) for item in structure if item != ""]
        else:
            return structure

    def get_props(self):
        return self.clean_structure(self.props)

    def get_nonha_deployment_params(self):
        return {
            "accountId": self.input_params.get("accountId"),
            "productId": self.input_params.get("productId"),
            "planTemplateId": self.input_params.get("planTemplateId"),
            "planTemplateName": self.input_params.get("planTemplateName"),
            "region": self.input_params.get("region"),
            "cloudProvider": self.input_params.get("cloudProvider"),
            "availabilityScenario": self.input_params.get("availabilityScenario"),
            "infrastructureParameterSet": {
                "operatingSystem": self.infrastructureParameterSet.get(
                    "operatingSystem"
                ),
                "privateDnsZone": self.infrastructureParameterSet.get("privateDnsZone"),
                "reversePrivateDnsZone": self.infrastructureParameterSet.get(
                    "reversePrivateDnsZone"
                ),
                "transitNetwork": self.infrastructureParameterSet.get("transitNetwork"),
                "workloadNetwork": self.infrastructureParameterSet.get(
                    "workloadNetwork"
                ),
                "sharedServicesNetwork": self.infrastructureParameterSet.get(
                    "sharedServicesNetwork"
                ),
                "sharedServicesSubnet": self.infrastructureParameterSet.get(
                    "sharedServicesSubnet"
                ),
                "workloadNetworkHanaSubnet": self.infrastructureParameterSet.get(
                    "workloadNetworkHanaSubnet"
                ),
                "workloadNetworkAsSubnet": self.infrastructureParameterSet.get(
                    "workloadNetworkAsSubnet"
                ),
                "hanaVmSize": self.infrastructureParameterSet.get("hanaVmSize"),
                "centralServicesVmSize": self.infrastructureParameterSet.get(
                    "centralServicesVmSize"
                ),
                "enqueueReplicationServerVmSize": self.infrastructureParameterSet.get(
                    "enqueueReplicationServerVmSize"
                ),
                "applicationServerVmSize": self.infrastructureParameterSet.get(
                    "applicationServerVmSize"
                ),
                "numberOfApplicationServers": self.infrastructureParameterSet.get(
                    "numberOfApplicationServers"
                ),
                "webDispatcherVmSize": self.infrastructureParameterSet.get(
                    "webDispatcherVmSize"
                ),
            },
            "installationParameterSets": {
                "downloadBinaries": {
                    "name": "Download Binaries",
                    "parameters": [
                        {
                            "name": "technicalCommunicationUser",
                            "value": self.infrastructureParameterSet.get(
                                "technicalCommunicationUser"
                            ),
                        },
                        {
                            "name": "techUserPassword",
                            "value": self.infrastructureParameterSet.get(
                                "techUserPassword"
                            ),
                        },
                        {
                            "name": "maintenancePlannerTransaction",
                            "value": self.infrastructureParameterSet.get(
                                "maintenancePlannerTransaction"
                            ),
                        },
                    ],
                },
                "hanaDeployment": {
                    "name": "HANA Deployment",
                    "parameters": [
                        {
                            "name": "DBSID",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("DBSID"),
                        },
                        {
                            "name": "DBSIDAdminUserId",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("DBSIDAdminUserId"),
                        },
                        {
                            "name": "instanceNumber",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("instanceNumber"),
                        },
                        {
                            "name": "primaryHanaPhysicalHostname",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("primaryHanaPhysicalHostname"),
                        },
                        {
                            "name": "primaryHanaVirtualHostname",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("primaryHanaVirtualHostname"),
                        },
                    ],
                },
                "s4hanaDeployment": {
                    "name": "S/4HANA Deployment",
                    "parameters": [
                        {
                            "name": "SID",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SID"),
                        },
                        {
                            "name": "SAPSysAdminUserId",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SAPSysAdminUserId"),
                        },
                        {
                            "name": "SAPSysAdminGroupId",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SAPSysAdminGroupId"),
                        },
                        {
                            "name": "sapGuiDefaultLanguage",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("sapGuiDefaultLanguage"),
                        },
                        {
                            "name": "SAPSystemAdditionalLanguages",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SAPSystemAdditionalLanguages"),
                        },
                        {
                            "name": "numberOfDialogWorkProcesses",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("numberOfDialogWorkProcesses"),
                        },
                        {
                            "name": "numberOfBatchWorkProcesses",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("numberOfBatchWorkProcesses"),
                        },
                    ],
                },
                "centralServicesDeployment": {
                    "name": "ABAP SAP Central Services Deployment",
                    "parameters": [
                        {
                            "name": "instanceNumber",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("instanceNumber"),
                        },
                        {
                            "name": "ABAPMessageServerPort",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("ABAPMessageServerPort"),
                        },
                        {
                            "name": "physicalHostname",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("physicalHostname"),
                        },
                        {
                            "name": "virtualHostname",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("virtualHostname"),
                        },
                    ],
                },
                "primaryApplicationServerDeployment": {
                    "name": "Primary Application Server Deployment",
                    "parameters": [
                        {
                            "name": "instanceNumber",
                            "value": self.installationParameterSets.get(
                                "primaryApplicationServerDeployment"
                            ).get("instanceNumber"),
                        },
                        {
                            "name": "physicalHostname",
                            "value": self.installationParameterSets.get(
                                "primaryApplicationServerDeployment"
                            ).get("physicalHostname"),
                        },
                        {
                            "name": "virtualHostname",
                            "value": self.installationParameterSets.get(
                                "primaryApplicationServerDeployment"
                            ).get("virtualHostname"),
                        },
                    ],
                },
                "additionalApplicationServersDeployment": self.installationParameterSets.get(
                    "additionalApplicationServersDeployment"
                ),
                "webDispatcherDeployment": {
                    "name": "SAP Web Dispatcher and Fiori Configuration",
                    "parameters": [
                        {
                            "name": "installationType",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("installationType"),
                        }
                    ],
                },
            },
        }

    def get_nonha_provisioning_params(self):
        params = {
            "productId": self.input_params.get("productId"),
            "planTemplateId": self.input_params.get("planTemplateId"),
            "availabilityScenario": self.input_params.get("availabilityScenario"),
            "adaptiveDeployment": "false",
            "dryRun": "false",
            "infrastructureParameterSet": {
                ###  privateDnsZone or domainName is added ###
                "deploymentServerSubnet": self.infrastructureParameterSet.get(
                    "deploymentServerSubnet"
                ),
                "executionEngineSubnet": self.infrastructureParameterSet.get(
                    "executionEngineSubnet"
                ),
                "osUser": self.infrastructureParameterSet.get("remoteOsUser"),
                "secretStoreId": self.infrastructureParameterSet.get("secretStoreId"),
                "sshPublicKeySecretName": self.infrastructureParameterSet.get(
                    "sshPublicKeySecretName"
                ),
                "sshPrivateKeySecretName": self.infrastructureParameterSet.get(
                    "sshPrivateKeySecretName"
                ),
                "deploymentServerResourceGroup": self.infrastructureParameterSet.get(
                    "deploymentServerResourceGroup"
                ),
                "parameters": [],
            },
            "deploymentParameterSets": {
                "downloadUser": {
                    "name": "Download User",
                    "parameters": [
                        {
                            "name": "technicalCommunicationUser",
                            "value": self.infrastructureParameterSet.get(
                                "technicalCommunicationUser"
                            ),
                        },
                        {
                            "name": "techUserPassword",
                            "value": self.infrastructureParameterSet.get(
                                "techUserPassword"
                            ),
                        },
                    ],
                },
                "hanaDeployment": {
                    "name": "HANA Deployment",
                    "parameters": [
                        {
                            "name": "primaryVmResourceId",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("primaryVmResourceId"),
                        },
                        {
                            "name": "DBSID",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("DBSID"),
                        },
                        {
                            "name": "DBSIDAdminUserId",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("DBSIDAdminUserId"),
                        },
                        {
                            "name": "instanceNumber",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("instanceNumber"),
                        },
                        {
                            "name": "primaryPhysicalHostname",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("primaryPhysicalHostname"),
                        },
                        {
                            "name": "primaryVirtualHostname",
                            "value": self.installationParameterSets.get(
                                "hanaDeployment"
                            ).get("primaryVirtualHostname"),
                        },
                    ],
                },
                "s4hanaDeployment": {
                    "name": "S/4HANA Deployment",
                    "parameters": [
                        {
                            "name": "SID",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SID"),
                        },
                        {
                            "name": "SAPSysAdminUserId",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SAPSysAdminUserId"),
                        },
                        {
                            "name": "SAPSysAdminGroupId",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SAPSysAdminGroupId"),
                        },
                        {
                            "name": "sapGuiDefaultLanguage",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("sapGuiDefaultLanguage"),
                        },
                        {
                            "name": "SAPSystemAdditionalLanguages",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("SAPSystemAdditionalLanguages"),
                        },
                        {
                            "name": "numberOfDialogWorkProcesses",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("numberOfDialogWorkProcesses"),
                        },
                        {
                            "name": "numberOfBatchWorkProcesses",
                            "value": self.installationParameterSets.get(
                                "s4hanaDeployment"
                            ).get("numberOfBatchWorkProcesses"),
                        },
                    ],
                },
                "centralServicesDeployment": {
                    "name": "ABAP SAP Central Services Deployment",
                    "parameters": [
                        {
                            "name": "vmResourceId",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("vmResourceId"),
                        },
                        {
                            "name": "instanceNumber",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("instanceNumber"),
                        },
                        {
                            "name": "ABAPMessageServerPort",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("ABAPMessageServerPort"),
                        },
                        {
                            "name": "physicalHostname",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("physicalHostname"),
                        },
                        {
                            "name": "virtualHostname",
                            "value": self.installationParameterSets.get(
                                "centralServicesDeployment"
                            ).get("virtualHostname"),
                        },
                    ],
                },
                "fioriConfiguration": {
                    "name": "SAP Fiori Configuration",
                    "parameters": [
                        {
                            "name": "fioriHostname",
                            "value": self.installationParameterSets.get(
                                "fioriConfiguration"
                            ).get("fioriHostname"),
                        },
                        {
                            "name": "fioriHostPort",
                            "value": self.installationParameterSets.get(
                                "fioriConfiguration"
                            ).get("fioriHostPort"),
                        },
                        {
                            "name": "productiveClientNumber",
                            "value": self.installationParameterSets.get(
                                "fioriConfiguration"
                            ).get("productiveClientNumber"),
                        },
                        {
                            "name": "ossUser",
                            "value": self.installationParameterSets.get(
                                "fioriConfiguration"
                            ).get("ossUser"),
                        },
                        {
                            "name": "ossUserPassword",
                            "value": self.installationParameterSets.get(
                                "fioriConfiguration"
                            ).get("ossUserPassword"),
                        },
                    ],
                },
                "webDispatcherDeployment": {
                    "name": "SAP Web Dispatcher Configuration",
                    "parameters": [
                        {
                            "name": "installationType",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("installationType"),
                        },
                        {
                            "name": "primaryVmResourceId",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("primaryVmResourceId"),
                        },
                        {
                            "name": "virtualHostname",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("virtualHostname"),
                        },
                        {
                            "name": "primaryInstanceNumber",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("primaryInstanceNumber"),
                        },
                        {
                            "name": "primaryPhysicalHostname",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("primaryPhysicalHostname"),
                        },
                        {
                            "name": "primaryVirtualHostname",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("primaryVirtualHostname"),
                        },
                        {
                            "name": "userIdOfSIDAdmin",
                            "value": self.installationParameterSets.get(
                                "webDispatcherDeployment"
                            ).get("userIdOfSIDAdmin"),
                        },
                    ],
                },
            },
        }

        self.transform_application_servers()
        params["deploymentParameterSets"]["applicationServersDeployment"] = (
            self.installationParameterSets.get("applicationServersDeployment")
        )

        # Check if privateDnsZone is provided, and add it to infrastructure parameters if true
        if self.infrastructureParameterSet.get("privateDnsZone") is not None:
            params["infrastructureParameterSet"]["privateDnsZone"] = (
                self.infrastructureParameterSet.get("privateDnsZone")
            )

        # Check if domainName is provided, and add it to infrastructure parameters if true
        if self.infrastructureParameterSet.get("domainName") is not None:
            params["infrastructureParameterSet"]["domainName"] = (
                self.infrastructureParameterSet.get("domainName")
            )

        if self.infrastructureParameterSet.get("techUserPasswordReference") is not None:
            new_parameter = {
                "name": "passwordReference",
                "value": self.infrastructureParameterSet.get(
                    "techUserPasswordReference"
                ),
            }
            params["deploymentParameterSets"]["downloadUser"]["parameters"].append(
                new_parameter
            )
        if (
            self.installationParameterSets.get("fioriConfiguration").get(
                "ossUserPasswordReference"
            )
            is not None
        ):
            new_parameter = {
                "name": "ossUserPasswordReference",
                "value": self.installationParameterSets.get("fioriConfiguration").get(
                    "ossUserPasswordReference"
                ),
            }
            params["deploymentParameterSets"]["fioriConfiguration"][
                "parameters"
            ].append(new_parameter)
        return params

    def get_ha_deployment_params(self):
        return dict(
            hanaDeployment={
                "name": "HANA Deployment",
                "parameters": [
                    {
                        "name": "DBSID",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("DBSID"),
                    },
                    {
                        "name": "DBSIDAdminUserId",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("DBSIDAdminUserId"),
                    },
                    {
                        "name": "instanceNumber",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("instanceNumber"),
                    },
                    {
                        "name": "frontendHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("frontendHostname"),
                    },
                    {
                        "name": "primaryHanaPhysicalHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("primaryHanaPhysicalHostname"),
                    },
                    {
                        "name": "primaryHanaVirtualHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("primaryHanaVirtualHostname"),
                    },
                    {
                        "name": "secondaryHanaPhysicalHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("secondaryHanaPhysicalHostname"),
                    },
                    {
                        "name": "secondaryHanaVirtualHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("secondaryHanaVirtualHostname"),
                    },
                ],
            },
            enqueueReplicationServerDeployment={
                "name": "Enqueue Replication Server Deployment",
                "parameters": [
                    {
                        "name": "instanceNumber",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("instanceNumber"),
                    },
                    {
                        "name": "physicalHostname",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("physicalHostname"),
                    },
                    {
                        "name": "virtualHostname",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("virtualHostname"),
                    },
                ],
            },
        )

    def get_cluster_deployment_params(self):
        return dict(
            clustering={
                "name": "Service Principal for High Availability Cluster",
                "parameters": [
                    {
                        "name": "clientId",
                        "value": self.installationParameterSets.get("clientId"),
                    },
                    {
                        "name": "clientSecret",
                        "value": self.installationParameterSets.get("clientSecret"),
                    },
                ],
            }
        )

    def get_webdisp_deployment_standalone_params(self):
        return dict(
            parameters=(
                {
                    "name": "primaryInstanceNumber",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("primaryInstanceNumber"),
                },
                {
                    "name": "primaryPhysicalHostname",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("primaryPhysicalHostname"),
                },
                {
                    "name": "primaryVirtualHostname",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("primaryVirtualHostname"),
                },
                {
                    "name": "userIdOfSIDAdmin",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("userIdOfSIDAdmin"),
                },
                {
                    "name": "fioriHostPort",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("fioriHostPort"),
                },
                {
                    "name": "virtualHostname",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("virtualHostname"),
                },
            )
        )

    def get_webdisp_ha_deployment_params(self):
        return dict(
            parameters=(
                {
                    "name": "secondaryInstanceNumber",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("secondaryInstanceNumber"),
                },
                {
                    "name": "secondaryPhysicalHostname",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("secondaryPhysicalHostname"),
                },
                {
                    "name": "secondaryVirtualHostname",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("secondaryVirtualHostname"),
                },
                {
                    "name": "fioriHostname",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("fioriHostname"),
                },
                {
                    "name": "fioriHostPort",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("fioriHostPort"),
                },
                {
                    "name": "productiveClientNumber",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("productiveClientNumber"),
                },
            )
        )

    def get_webdisp_deployment_params(self):
        return dict(
            parameters=(
                {
                    "name": "fioriHostname",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("fioriHostname"),
                },
                {
                    "name": "fioriHostPort",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("fioriHostPort"),
                },
                {
                    "name": "productiveClientNumber",
                    "value": self.installationParameterSets.get(
                        "webDispatcherDeployment"
                    ).get("productiveClientNumber"),
                },
            )
        )

    def get_ha_provisioning_params(self):
        params = dict(
            hanaDeployment={
                "name": "HANA Deployment",
                "parameters": [
                    {
                        "name": "primaryVmResourceId",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("primaryVmResourceId"),
                    },
                    {
                        "name": "DBSID",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("DBSID"),
                    },
                    {
                        "name": "DBSIDAdminUserId",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("DBSIDAdminUserId"),
                    },
                    {
                        "name": "instanceNumber",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("instanceNumber"),
                    },
                    {
                        "name": "primaryPhysicalHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("primaryPhysicalHostname"),
                    },
                    {
                        "name": "primaryVirtualHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("primaryVirtualHostname"),
                    },
                    {
                        "name": "secondaryVmResourceId",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("secondaryVmResourceId"),
                    },
                    {
                        "name": "loadBalancerResourceId",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("loadBalancerResourceId"),
                    },
                    {
                        "name": "frontEndIp",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("frontEndIp"),
                    },
                    {
                        "name": "frontendHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("frontendHostname"),
                    },
                    {
                        "name": "secondaryPhysicalHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("secondaryPhysicalHostname"),
                    },
                    {
                        "name": "secondaryVirtualHostname",
                        "value": self.installationParameterSets.get(
                            "hanaDeployment"
                        ).get("secondaryVirtualHostname"),
                    },
                ],
            },
            centralServicesDeployment={
                "name": "ABAP SAP Central Services Deployment",
                "parameters": [
                    {
                        "name": "loadBalancerResourceId",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("loadBalancerResourceId"),
                    },
                    {
                        "name": "loadBalancerHostname",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("loadBalancerHostname"),
                    },
                    {
                        "name": "frontEndIp",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("frontEndIp"),
                    },
                    {
                        "name": "vmResourceId",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("vmResourceId"),
                    },
                    {
                        "name": "instanceNumber",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("instanceNumber"),
                    },
                    {
                        "name": "ABAPMessageServerPort",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("ABAPMessageServerPort"),
                    },
                    {
                        "name": "physicalHostname",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("physicalHostname"),
                    },
                    {
                        "name": "virtualHostname",
                        "value": self.installationParameterSets.get(
                            "centralServicesDeployment"
                        ).get("virtualHostname"),
                    },
                ],
            },
            enqueueReplicationServerDeployment={
                "name": "Enqueue Replication Server Deployment",
                "parameters": [
                    {
                        "name": "vmResourceId",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("vmResourceId"),
                    },
                    {
                        "name": "loadBalancerHostname",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("loadBalancerHostname"),
                    },
                    {
                        "name": "frontEndIp",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("frontEndIp"),
                    },
                    {
                        "name": "instanceNumber",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("instanceNumber"),
                    },
                    {
                        "name": "physicalHostname",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("physicalHostname"),
                    },
                    {
                        "name": "virtualHostname",
                        "value": self.installationParameterSets.get(
                            "enqueueReplicationServerDeployment"
                        ).get("virtualHostname"),
                    },
                ],
            },
            webDispatcherDeployment={
                "name": "SAP Web Dispatcher and Fiori Configuration",
                "parameters": [
                    {
                        "name": "installationType",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("installationType"),
                    },
                    {
                        "name": "primaryVmResourceId",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("primaryVmResourceId"),
                    },
                    {
                        "name": "virtualHostname",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("virtualHostname"),
                    },
                    {
                        "name": "primaryInstanceNumber",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("primaryInstanceNumber"),
                    },
                    {
                        "name": "primaryPhysicalHostname",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("primaryPhysicalHostname"),
                    },
                    {
                        "name": "primaryVirtualHostname",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("primaryVirtualHostname"),
                    },
                    {
                        "name": "userIdOfSIDAdmin",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("userIdOfSIDAdmin"),
                    },
                    {
                        "name": "secondaryVmResourceId",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("secondaryVmResourceId"),
                    },
                    {
                        "name": "loadBalancerResourceId",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("loadBalancerResourceId"),
                    },
                    {
                        "name": "frontEndIp",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("frontEndIp"),
                    },
                    {
                        "name": "secondaryInstanceNumber",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("secondaryInstanceNumber"),
                    },
                    {
                        "name": "secondaryPhysicalHostname",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("secondaryPhysicalHostname"),
                    },
                    {
                        "name": "secondaryVirtualHostname",
                        "value": self.installationParameterSets.get(
                            "webDispatcherDeployment"
                        ).get("secondaryVirtualHostname"),
                    },
                ],
            },
        )
        return params

    def transform_application_servers(self):
        application_servers = self.installationParameterSets.get(
            "applicationServersDeployment", []
        )

        transformed_application_servers = []
        for index, server in enumerate(application_servers, start=1):
            name = f"Application Server {index} Deployment"
            parameters = [
                {"name": "vmResourceId", "value": server.get("vmResourceId", "")},
                {"name": "instanceNumber", "value": server.get("instanceNumber", "")},
                {
                    "name": "physicalHostname",
                    "value": server.get("physicalHostname", ""),
                },
                {"name": "virtualHostname", "value": server.get("virtualHostname", "")},
            ]

            transformed_application_servers.append(
                {"name": name, "parameters": parameters}
            )

        self.installationParameterSets["applicationServersDeployment"] = (
            transformed_application_servers
        )


class Connection:
    def __init__(self, address, outputDir, outputFile):
        self._address = address.rstrip("/")
        self._headers = {}
        self._client = Request()
        self.logLocation = f"{outputDir}/{outputFile}"

    def _request(self, method, path, payload=None):
        headers = self._headers.copy()
        data = None
        if payload:
            data = json.dumps(payload)
            headers["Content-Type"] = "application/json"

        url = self._address + path
        r_data = {}  # Initialize r_data to avoid referencing an uninitialized variable
        try:
            r = self._client.open(method, url, data=data, headers=headers, timeout=60)
            r_status = r.getcode()
            r_headers = dict(r.headers)
            data = r.read().decode("utf-8")
            r_data = json.loads(data) if data else {}
        except HTTPError as e:
            r_status = e.code
            r_headers = dict(e.headers)
            try:
                r_data = e.read().decode("utf-8")

            except UnicodeDecodeError:
                raise AnsibleConnectionFailure(f"HTTPError {r_status}: {r_headers}")
            raise AnsibleConnectionFailure(
                f"HTTPError {r_status}: {r_headers} Response {r_data}"
            )
        finally:
            if isinstance(r_data, str):
                r_data = json.loads(r_data)
            file_data = r_data.copy()
            with open(self.logLocation, "w") as f:
                if file_data.get("access_token"):
                    file_data.pop("access_token")
                json.dump(file_data, f, sort_keys=True, indent=4)
        return r_status, r_headers, r_data

    def get(self, path):
        return self._request("GET", path)

    def post(self, path, payload=None):
        return self._request("POST", path, payload)

    def delete(self, path):
        return self._request("DELETE", path)

    def get_full_path(self, file_name):
        absolute_path = os.path.dirname(__file__)
        relative_path = file_name
        full_path = os.path.join(absolute_path, relative_path)
        return full_path

    def login(self, oauthServerUrl, apiEndpoint):
        self._address = oauthServerUrl
        self._client.client_cert, cert_temp_file = self.create_temp_file_from_encrypted(
            self.get_full_path("cert_file.pem")
        )
        self._client.client_key, key_temp_file = self.create_temp_file_from_encrypted(
            self.get_full_path("key_file")
        )
        status, headers, data = self.post("")
        try:
            if status in [200, 201, 204, 206]:
                token = data.get("access_token")
                self._address = apiEndpoint
                if token is not None:
                    self._headers["Authorization"] = "Bearer " + token
            else:
                raise AnsibleActionFail(
                    "Unable to fetch CAL token. Exit code %s" % status
                )
        finally:
            # Clean up temporary files
            if self.get_full_path("cert_file.pem"):
                os.remove(self.get_full_path("cert_file.pem"))
            if self.get_full_path("key_file"):
                os.remove(self.get_full_path("key_file"))
            self._client.client_cert = None
            self._client.client_key = None

    def create_temp_file_from_encrypted(self, encrypted_file_path):
        with open(encrypted_file_path, "rb") as file:
            encrypted_data = file.read()
        decrypted_data = fernet.decrypt(encrypted_data).decode()

        fd, temp_file_path = tempfile.mkstemp()
        with os.fdopen(fd, "w") as tmp:
            tmp.write(decrypted_data)

        return temp_file_path, temp_file_path

    def decrypt_file(self, file_path):
        with open(file_path, "rb") as file:
            encrypted_data = file.read()
        decrypted_data = fernet.decrypt(encrypted_data).decode()
        with open(file_path, "w") as file:
            file.write(decrypted_data)


class AzureKeyVaultManager:
    def __init__(self, vault_url, client_id=None, secret=None, tenant=None):
        self.vault_url = vault_url
        self.client_id = client_id
        self.secret = secret
        self.tenant = tenant
        self.token = None
        self.token_acquired = False
        self.get_token()

    def get_token(self):
        display = Display()
        token_params = {
            "api-version": "2018-02-01",
            "resource": "https://vault.azure.net",
        }
        token_headers = {"Metadata": "true"}
        try:
            token_res = requests.get(
                "http://169.254.169.254/metadata/identity/oauth2/token",
                params=token_params,
                headers=token_headers,
            )
            token = token_res.json().get("access_token")
            if token is not None:
                self.token_acquired = True
                self.token = token
            else:
                display.v("No token was available.")
        except requests.exceptions.RequestException:
            display.v(
                "Try using service principal if provided. Unable to fetch MSI token. "
            )
            self.token_acquired = False

    def get_secrets(self, secrets):
        ret = []
        if self.vault_url is None:
            raise AnsibleActionFail("Failed to get a valid vault URL.")
        if self.token_acquired:
            secret_params = {"api-version": "2016-10-01"}
            secret_headers = {"Authorization": "Bearer " + self.token}
            for secret in secrets:
                try:
                    secret_res = requests.get(
                        self.vault_url + "/secrets/" + secret,
                        params=secret_params,
                        headers=secret_headers,
                    )
                    ret.append(secret_res.json()["value"])
                except requests.exceptions.RequestException:
                    raise AnsibleActionFail(
                        "Failed to fetch secret: " + secret + " via MSI endpoint."
                    )
                except KeyError:
                    raise AnsibleActionFail("Failed to fetch secret " + secret + ".")
            return ret
        else:
            return self.get_secret_non_msi(secrets)

    def get_secret_non_msi(self, secrets):
        try:
            credentials = ServicePrincipalCredentials(
                client_id=self.client_id, secret=self.secret, tenant=self.tenant
            )
            client = KeyVaultClient(credentials)
        except AuthenticationError:
            raise AnsibleActionFail(
                "Invalid credentials for the subscription provided."
            )

        ret = []
        for secret in secrets:
            try:
                secret_val = client.get_secret(self.vault_url, secret, "").value
                ret.append(secret_val)
            except ClientRequestError:
                raise AnsibleActionFail("Error occurred in the request")
        return ret

    def create_certificates_files(self, client_cert, client_key):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        cert_file_path = os.path.join(script_dir, "cert_file.pem")
        key_file_path = os.path.join(script_dir, "key_file")
        # Encrypt and save the certificates
        self.encrypt_and_save(client_cert, cert_file_path)
        self.encrypt_and_save(client_key, key_file_path)

    def encrypt_and_save(self, data, file_path):
        encrypted_data = fernet.encrypt(data.encode())
        with open(file_path, "wb") as file:
            file.write(encrypted_data)


class ActionModule(ActionBase):
    def __init__(self, *args, **kwargs):
        super(ActionModule, self).__init__(*args, **kwargs)
        self._supports_check_mode = False

    def run(self, tmp=None, task_vars=None):
        result = super(ActionModule, self).run(tmp, task_vars)
        # Get parameters from task arguments
        method = self._task.args.get("method")
        output_directory = self._task.args.get("outputDirectoryPath", "/tmp")
        output_file = self._task.args.get("outputFile", "output.txt")
        azure_arg_mapping = {
            "calKeyvaultId": "vault_url",
            "clientId": "client_id",
            "clientSecret": "secret",
            "tenantId": "tenant",
        }

        # Extract relevant arguments and map them to AzureKeyVaultManager constructor argument names
        azure_args = {
            azure_arg_mapping[key]: value
            for key, value in self._task.args.items()
            if key in azure_arg_mapping
        }

        # Retrieve secrets from Azure Key Vault
        azure_mngr = AzureKeyVaultManager(**azure_args)
        api_secrets = azure_mngr.get_secrets(
            ["apiEndpoint", "clientCertificate", "clientPrivateKey", "oauthServerUrl"]
        )

        apiEndPoint, clientCertificate, clientPrivateKey, oathUrl = api_secrets

        # Create certificate files
        azure_mngr.create_certificates_files(clientCertificate, clientPrivateKey)

        conn = Connection("", output_directory, output_file)

        if method == "get_product":
            validation_result, new_module_args = self.validate_argument_spec(
                method_spec_product, required_together=required_together
            )
            conn.login(oathUrl, apiEndPoint)
            status, _, data = conn.get("/solutions/v1/products")
            result.update(status=status, response=str(data))
        elif method == "get_progress":
            validation_result, new_module_args = self.validate_argument_spec(
                method_spec_progress, required_together=required_together
            )
            conn.login(oathUrl, apiEndPoint)
            system_id = new_module_args.get("systemId")
            status, _, data = conn.get(
                "/workloads/v1/systems/" + system_id + "/provisioningProgress"
            )
            result.update(status=status, response=str(data))
        elif method == "deployment":
            validation_result, new_module_args = self.validate_argument_spec(
                method_spec_deployment, required_together=required_together
            )
            conn.login(oathUrl, apiEndPoint)
            status, _, data = conn.get("/solutions/v1/products")

            if data is not None:
                products_dict = {p["productId"]: p for p in data.get("products")}
                product = products_dict.get(new_module_args.get("productId"))
                product_constraints = [
                    item
                    for item in product.get("availableProviders")
                    if "Microsoft Azure" in item["name"]
                ][0]
                if not product:
                    raise AnsibleActionFail(
                        "Product not found. Choose from the available products' list %s"
                        % products_dict
                    )

            method_spec_deployment.get("infrastructureParameterSet").get("options").get(
                "operatingSystem"
            ).update({"choices": product_constraints.get("availableOperatingSystems")})
            method_spec_deployment.get("infrastructureParameterSet").get("options").get(
                "hanaVmSize"
            ).update({"choices": product_constraints.get("availableHanaVmSizes")})
            method_spec_deployment.get("infrastructureParameterSet").get("options").get(
                "centralServicesVmSize"
            ).update(
                {"choices": product_constraints.get("availableCentralServicesVmSizes")}
            )
            method_spec_deployment.get("infrastructureParameterSet").get("options").get(
                "enqueueReplicationServerVmSize"
            ).update(
                {
                    "choices": product_constraints.get(
                        "availableEnqueueReplicationServerVmSizes"
                    )
                }
            )
            method_spec_deployment.get("infrastructureParameterSet").get("options").get(
                "applicationServerVmSize"
            ).update(
                {
                    "choices": product_constraints.get(
                        "availableApplicationServerVmSizes"
                    )
                }
            )
            method_spec_deployment.get("infrastructureParameterSet").get("options").get(
                "webDispatcherVmSize"
            ).update(
                {"choices": product_constraints.get("availableWebDispatcherVmSizes")}
            )

            validation_result, new_module_args = self.validate_argument_spec(
                method_spec_deployment
            )
            system = SAPsystem(new_module_args)
            system_request = system.get_props()
            status, _, data = conn.post(
                "/workloads/v1/systems/provisioning", payload=system_request
            )
            result.update(status=status, response=str(data))
        elif method == "software_provisioning":
            conn.login(oathUrl, apiEndPoint)
            validation_result, new_module_args = self.validate_argument_spec(
                method_spec_provisioning, required_together=required_together
            )
            system = SAPsystem(new_module_args)
            system_request = system.get_props()
            status, _, data = conn.post(
                "/workloads/v1/systems/softwareProvisioning", payload=system_request
            )
            result.update(
                status=status, response=str(data)
            )  # Write response to output file

            result["changed"] = True

        return result
