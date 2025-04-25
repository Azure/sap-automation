# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = """
    lookup: azure_app_config
    author:
        - Hai Cao <cao.hai@microsoft.com>
        - SDAF Core Dev Team <sdaf_core_team@microsoft.com>
    version_added: 2.16
    requirements:
        - requests
        - azure-identity
        - azure-appconfiguration
    short_description: Read configuration value from Azure App Configuration.
    description:
      - This lookup returns the content of a configuration value saved in Azure App Configuration.
      - When ansible host is MSI enabled Azure VM, user don't need provide any credential to access to Azure App Configuration.
    options:
        _terms:
            description: Configuration key.
            required: True
        config_label:
            description: Label for the configuration setting.
            required: False
        appconfig_url:
            description: URL of Azure App Configuration.
            required: True
        client_id:
            description: Client id of service principal that has access to the Azure App Configuration.
            required: False
        client_secret:
            description: Secret of the service principal.
            required: False
        tenant_id:
            description: Tenant id of service principal.
            required: False
        timeout:
            description: Timeout (in seconds) for checking endpoint responsiveness. Default is 5.
            required: False
    notes:
        - If Ansible is running on an Azure Virtual Machine with MSI enabled, client_id, client_secret and tenant_id aren't required.
        - |
            For enabling MSI on Azure VM, please refer to:
            https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/
        - After enabling MSI on Azure VM, remember to grant access of the App Configuration to the VM by adding a new Access Policy in Azure Portal.
        - If MSI is not enabled on Ansible host, it's required to provide a valid service principal which has access to the App Configuration.
"""

EXAMPLES = """
- name: Look up configuration value when Ansible host is MSI enabled Azure VM
  debug: msg="The configuration value is {{lookup('azure_appconfig', 'testConfig', appconfig_url='https://yourappconfig.azconfig.io')}}"

- name: Look up configuration value when Ansible host is general VM
  vars:
    url: 'https://yourappconfig.azconfig.io'
    config_key: 'testConfig'
    client_id: '123456789'
    client_secret: 'abcdefg'
    tenant_id: 'uvwxyz'
    timeout: 10
  debug: msg="The configuration value is {{lookup('azure_appconfig', config_key, appconfig_url=url, client_id=client_id, client_secret=client_secret, tenant_id=tenant_id, timeout=timeout)}}"
"""

RETURN = """
  _raw:
    description: configuration value string
"""

from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase
from ansible.utils.display import Display
from azure.identity import (
    DefaultAzureCredential,
    ClientSecretCredential,
    ManagedIdentityCredential,
)
from azure.appconfiguration import AzureAppConfigurationClient
import time
import requests

display = Display()


class AzureAppConfigHelper:
    """
    A helper class for retrieving configuration settings from Azure App Configuration.
    It handles URL responsiveness (public vs. private endpoints), credential selection,
    and configuration retrieval.
    """

    def __init__(
        self,
        appconfig_url,
        client_id=None,
        client_secret=None,
        tenant_id=None,
        timeout=5,
    ):
        """
        Initialize the helper with the provided App Configuration URL and credentials.
        :param appconfig_url: The base URL for Azure App Configuration.
        :param client_id: Optional client (or managed identity) ID.
        :param client_secret: Optional client secret.
        :param tenant_id: Optional tenant id.
        :param timeout: Timeout (in seconds) for responsiveness check.
        """
        self.credential = self.get_credential(client_id, client_secret, tenant_id)
        self.client = AzureAppConfigurationClient(
            base_url=appconfig_url, credential=self.credential
        )
        display.v(
            f"Initialized AzureAppConfigHelper with appconfig_url: {appconfig_url}"
        )

    def get_credential(self, client_id, client_secret, tenant_id):
        """
        Returns the appropriate credential based on provided parameters.
        Implements secure credential handling with additional logging.

        1. If all three parameters are provided, it uses ClientSecretCredential.
        2. If only client_id is provided, it uses ManagedIdentityCredential.
        3. If none are provided, it falls back to DefaultAzureCredential.
        4. If any error occurs during credential initialization, it logs the error and raises an AnsibleError.

        :param client_id: Application (client) ID
        :type client_id: str
        :param client_secret: The client secret
        :type client_secret: str
        :param tenant_id: The Azure tenant ID
        :type tenant_id: str
        :raises AnsibleError: Thrown if credential initialization fails
        :return: An Azure credential object
        :rtype: azure.identity.DefaultAzureCredential
        """
        try:
            if all([client_id, client_secret, tenant_id]):
                display.v(
                    f"Using service principal authentication with client_id: {client_id[:6]}..."
                )
                return ClientSecretCredential(
                    client_id=client_id,
                    client_secret=client_secret,
                    tenant_id=tenant_id,
                )
            elif client_id:
                display.v(
                    f"Using managed identity authentication with client_id: {client_id[:6]}..."
                )
                return ManagedIdentityCredential(client_id=client_id)
            else:
                display.v(
                    "No explicit credentials provided, falling back to DefaultAzureCredential"
                )
                return DefaultAzureCredential(
                    exclude_shared_token_cache_credential=True
                )
        except Exception as e:
            display.error(f"Failed to initialize Azure credentials: {str(e)}")
            raise AnsibleError(f"Authentication configuration error: {str(e)}")

    def get_configuration(self, config_key, config_label=None):
        """
        Retrieves the configuration setting from Azure App Configuration.
        :param config_key: The configuration key.
        :param config_label: The label (optional) for the configuration.
        :return: The value of the configuration setting.
        """
        max_retries = 3
        retry_delay = 1  # seconds

        for attempt in range(max_retries):
            try:
                display.v(
                    f"Attempt {attempt + 1}/{max_retries}: "
                    f"Fetching configuration key: {config_key} "
                    f"with label: {config_label or 'None'}"
                )

                config = self.client.get_configuration_setting(
                    key=config_key, label=config_label
                )

                if not config:
                    display.warning(f"No configuration found for key: {config_key}")
                    return None

                display.v(f"Successfully retrieved configuration for key: {config_key}")
                return config.value

            except Exception as e:
                if attempt < max_retries - 1:
                    display.warning(
                        f"Attempt {attempt + 1} failed: {str(e)}. "
                        f"Retrying in {retry_delay} seconds..."
                    )
                    time.sleep(retry_delay)
                else:
                    display.error(f"All attempts failed for key {config_key}: {str(e)}")
                    raise AnsibleError(
                        f"Failed to fetch configuration after {max_retries} attempts: {str(e)}"
                    )


class LookupModule(LookupBase):
    def run(self, terms, variables, **kwargs):
        # Input validation
        if not terms:
            raise AnsibleError("No configuration keys provided")

        appconfig_url = kwargs.get("appconfig_url")
        if not appconfig_url:
            raise AnsibleError("appconfig_url is required")

        # Sanitize and validate inputs
        config_label = kwargs.get("config_label")
        timeout = int(kwargs.get("timeout", 5))
        if timeout < 1:
            display.warning("Timeout value too low, setting to minimum of 1 second")
            timeout = 1

        # Initialize helper with proper error handling
        try:
            helper = AzureAppConfigHelper(
                appconfig_url=appconfig_url,
                client_id=kwargs.get("client_id"),
                client_secret=kwargs.get("client_secret"),
                tenant_id=kwargs.get("tenant_id"),
                timeout=timeout,
            )
        except Exception as e:
            raise AnsibleError(
                f"Failed to initialize Azure App Configuration client: {str(e)}"
            )

        # Process configuration keys
        results = []
        failed_keys = []

        for term in terms:
            try:
                value = helper.get_configuration(term, config_label)
                if value is None:
                    failed_keys.append(term)
                results.append(value)
            except Exception as e:
                failed_keys.append(term)
                display.error(f"Failed to fetch key {term}: {str(e)}")

        if failed_keys:
            raise AnsibleError(
                f"Failed to fetch the following keys: {', '.join(failed_keys)}"
            )

        return results
