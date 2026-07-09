# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for the ``azure_app_config`` Ansible lookup plugin.
"""

from types import SimpleNamespace
import pytest
from ansible.errors import AnsibleError
from deploy.ansible.lookup_plugins.azure_app_config import (
    AzureAppConfigHelper,
    LookupModule,
)

_MODULE = "deploy.ansible.lookup_plugins.azure_app_config"


class _StubAppConfigHelper:
    """
    Stand-in for :class:`AzureAppConfigHelper` returning canned values.

    :param values: A sequence of values returned in order by
        successive :meth:`get_configuration` calls.
    """

    def __init__(self, values):
        self._values = list(values)

    def get_configuration(self, *args, **kwargs):
        """
        :param args: Positional arguments (ignored).
        :param kwargs: Keyword arguments (ignored).
        :return: The next configured value.
        """
        return self._values.pop(0)


class TestAzureAppConfig:
    """
    Test suite covering every public class and method of
    ``deploy.ansible.lookup_plugins.azure_app_config``.
    """

    @pytest.fixture(autouse=True)
    def _no_sleep(self, mocker):
        """
        Prevent retry backoff from slowing down the test suite.

        :param mocker: pytest-mock fixture used to patch ``time.sleep``.
        """
        mocker.patch(f"{_MODULE}.time.sleep")

    @pytest.fixture
    def mock_client(self, mocker):
        """
        Patch ``AzureAppConfigurationClient`` so no real Azure calls occur.

        :param mocker: pytest-mock fixture used to create the patch.
        :return: The mock replacing ``AzureAppConfigurationClient``.
        """
        return mocker.patch(f"{_MODULE}.AzureAppConfigurationClient")

    def test_get_credential_returns_client_secret_credential_when_all_provided(
        self, mock_client, mocker
    ):
        """
        Happy path for :meth:`AzureAppConfigHelper.get_credential`.

        :param mock_client: Fixture patching ``AzureAppConfigurationClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        credential_cls = mocker.patch(f"{_MODULE}.ClientSecretCredential")
        helper = AzureAppConfigHelper(
            appconfig_url="https://example.azconfig.io",
            client_id="cid",
            client_secret="secret",
            tenant_id="tid",
        )
        credential_cls.assert_called_once_with(
            client_id="cid", client_secret="secret", tenant_id="tid"
        )
        assert helper.credential is credential_cls.return_value

    def test_get_credential_returns_managed_identity_credential_when_only_client_id(
        self, mock_client, mocker
    ):
        """
        Edge case for :meth:`AzureAppConfigHelper.get_credential`.

        :param mock_client: Fixture patching ``AzureAppConfigurationClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        credential_cls = mocker.patch(f"{_MODULE}.ManagedIdentityCredential")
        AzureAppConfigHelper(appconfig_url="https://example.azconfig.io", client_id="cid")
        credential_cls.assert_called_once_with(client_id="cid")

    def test_get_credential_returns_default_credential_when_nothing_provided(
        self, mock_client, mocker
    ):
        """
        Edge case for :meth:`AzureAppConfigHelper.get_credential`.

        :param mock_client: Fixture patching ``AzureAppConfigurationClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        credential_cls = mocker.patch(f"{_MODULE}.DefaultAzureCredential")
        AzureAppConfigHelper(appconfig_url="https://example.azconfig.io")
        credential_cls.assert_called_once_with(exclude_shared_token_cache_credential=True)

    def test_get_credential_initialization_failure_raises_ansible_error(self, mock_client, mocker):
        """
        Edge case for :meth:`AzureAppConfigHelper.get_credential`.

        :param mock_client: Fixture patching ``AzureAppConfigurationClient``.
        :param mocker: pytest-mock fixture used to force a credential failure.
        """
        mocker.patch(f"{_MODULE}.DefaultAzureCredential", side_effect=RuntimeError("boom"))
        with pytest.raises(AnsibleError, match="Authentication configuration error"):
            AzureAppConfigHelper(appconfig_url="https://example.azconfig.io")

    def test_get_configuration_returns_value_on_success(self, mock_client, mocker):
        """
        Happy path for :meth:`AzureAppConfigHelper.get_configuration`.

        :param mock_client: Fixture patching ``AzureAppConfigurationClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        mocker.patch(f"{_MODULE}.DefaultAzureCredential")
        setting = SimpleNamespace(value="my-value")
        mock_client.return_value.get_configuration_setting.return_value = setting
        helper = AzureAppConfigHelper(appconfig_url="https://example.azconfig.io")
        result = helper.get_configuration("my-key")
        assert result == "my-value"

    def test_get_configuration_returns_none_when_setting_missing(self, mock_client, mocker):
        """
        Edge case for :meth:`AzureAppConfigHelper.get_configuration`.

        :param mock_client: Fixture patching ``AzureAppConfigurationClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        mocker.patch(f"{_MODULE}.DefaultAzureCredential")
        mock_client.return_value.get_configuration_setting.return_value = None
        helper = AzureAppConfigHelper(appconfig_url="https://example.azconfig.io")
        result = helper.get_configuration("missing-key")
        assert result is None

    def test_get_configuration_raises_ansible_error_after_max_retries(self, mock_client, mocker):
        """
        Edge case for :meth:`AzureAppConfigHelper.get_configuration`.

        :param mock_client: Fixture patching ``AzureAppConfigurationClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        mocker.patch(f"{_MODULE}.DefaultAzureCredential")
        mock_client.return_value.get_configuration_setting.side_effect = RuntimeError("down")
        helper = AzureAppConfigHelper(appconfig_url="https://example.azconfig.io")
        with pytest.raises(AnsibleError, match="Failed to fetch configuration"):
            helper.get_configuration("flaky-key")
        assert mock_client.return_value.get_configuration_setting.call_count == 3

    def test_lookup_module_run_returns_values_for_each_term(self, mocker):
        """
        Happy path for :meth:`LookupModule.run`.

        :param mocker: pytest-mock fixture used to patch the helper class.
        """
        helper_instance = _StubAppConfigHelper(["value1", "value2"])
        mocker.patch(f"{_MODULE}.AzureAppConfigHelper", return_value=helper_instance)
        module = LookupModule()
        result = module.run(
            ["key1", "key2"], variables=None, appconfig_url="https://example.azconfig.io"
        )
        assert result == ["value1", "value2"]

    def test_lookup_module_run_raises_when_appconfig_url_missing(self):
        """
        Edge case for :meth:`LookupModule.run`.

        Verifies that a missing ``appconfig_url`` raises an
        :class:`AnsibleError` before any Azure call is attempted.
        """
        module = LookupModule()
        with pytest.raises(AnsibleError, match="appconfig_url is required"):
            module.run(["key1"], variables=None)

    def test_lookup_module_run_raises_when_no_terms_provided(self):
        """
        Edge case for :meth:`LookupModule.run`.

        Verifies that an empty ``terms`` list raises an
        :class:`AnsibleError`.
        """
        module = LookupModule()
        with pytest.raises(AnsibleError, match="No configuration keys provided"):
            module.run([], variables=None, appconfig_url="https://example.azconfig.io")

    def test_lookup_module_run_raises_when_key_fetch_fails(self, mocker):
        """
        Edge case for :meth:`LookupModule.run`.

        :param mocker: pytest-mock fixture used to patch the helper class.
        """
        helper_instance = _StubAppConfigHelper([None])
        mocker.patch(f"{_MODULE}.AzureAppConfigHelper", return_value=helper_instance)
        module = LookupModule()
        with pytest.raises(AnsibleError, match="Failed to fetch the following keys"):
            module.run(["missing-key"], variables=None, appconfig_url="https://example.azconfig.io")
