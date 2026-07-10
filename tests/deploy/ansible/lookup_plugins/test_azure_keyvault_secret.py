# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for the ``azure_keyvault_secret`` Ansible lookup plugin.
"""

from types import SimpleNamespace
import pytest
from ansible.errors import AnsibleError
from azure.core.exceptions import HttpResponseError
from deploy.ansible.lookup_plugins.azure_keyvault_secret import (
    AzureKeyVaultHelper,
    LookupModule,
)

_MODULE = "deploy.ansible.lookup_plugins.azure_keyvault_secret"


class _StubKeyVaultHelper:
    """
    Stand-in for :class:`AzureKeyVaultHelper` returning canned values.

    :param values: A sequence of values returned in order by
        successive :meth:`get_secret` calls.
    """

    def __init__(self, values):
        self._values = list(values)

    def get_secret(self, *args, **kwargs):
        """
        :param args: Positional arguments (ignored).
        :param kwargs: Keyword arguments (ignored).
        :return: The next configured value.
        """
        return self._values.pop(0)


class TestAzureKeyvaultSecret:
    """
    Test suite covering every public class and method of
    ``deploy.ansible.lookup_plugins.azure_keyvault_secret``.
    """

    @pytest.fixture(autouse=True)
    def _no_sleep(self, mocker):
        """
        Prevent exponential-backoff retries from slowing down the test suite.

        :param mocker: pytest-mock fixture used to patch ``time.sleep``.
        """
        mocker.patch(f"{_MODULE}.time.sleep")

    @pytest.fixture(autouse=True)
    def _default_credential(self, mocker):
        """
        Avoid real credential resolution for every test in this module.

        :param mocker: pytest-mock fixture used to patch
            ``DefaultAzureCredential``.
        """
        mocker.patch(f"{_MODULE}.DefaultAzureCredential")

    @pytest.fixture
    def mock_secret_client(self, mocker):
        """
        Patch ``SecretClient`` so no real Azure calls occur.

        :param mocker: pytest-mock fixture used to create the patch.
        :return: The mock replacing ``SecretClient``.
        """
        return mocker.patch(f"{_MODULE}.SecretClient")

    def test_get_credential_returns_client_secret_credential_when_all_provided(
        self, mock_secret_client, mocker
    ):
        """
        Happy path for :meth:`AzureKeyVaultHelper.get_credential`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        credential_cls = mocker.patch(f"{_MODULE}.ClientSecretCredential")
        mock_secret_client.return_value.list_properties_of_secrets.return_value = iter([1])
        AzureKeyVaultHelper(
            vault_url="https://example.vault.azure.net",
            client_id="cid",
            client_secret="secret",
            tenant_id="tid",
        )
        credential_cls.assert_called_once_with(
            client_id="cid", client_secret="secret", tenant_id="tid"
        )

    def test_get_credential_returns_managed_identity_credential_when_only_client_id(
        self, mock_secret_client, mocker
    ):
        """
        Edge case for :meth:`AzureKeyVaultHelper.get_credential`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        :param mocker: pytest-mock fixture used to patch the credential class.
        """
        credential_cls = mocker.patch(f"{_MODULE}.ManagedIdentityCredential")
        mock_secret_client.return_value.list_properties_of_secrets.return_value = iter([1])
        AzureKeyVaultHelper(vault_url="https://example.vault.azure.net", client_id="cid")
        credential_cls.assert_called_once_with(client_id="cid")

    def test_get_credential_returns_default_credential_when_nothing_provided(
        self, mock_secret_client
    ):
        """
        Edge case for :meth:`AzureKeyVaultHelper.get_credential`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        """
        mock_secret_client.return_value.list_properties_of_secrets.return_value = iter([1])

        AzureKeyVaultHelper(vault_url="https://example.vault.azure.net")

    def test_get_responsive_url_uses_private_url_when_responsive(self, mock_secret_client):
        """
        Happy path for :meth:`AzureKeyVaultHelper.get_responsive_url`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        """
        mock_secret_client.return_value.list_properties_of_secrets.return_value = iter([1])
        helper = AzureKeyVaultHelper(vault_url="https://example.vault.azure.net")
        assert helper.vault_url == "https://example.privatelink.vault.azure.net"

    def test_get_responsive_url_falls_back_to_public_url_on_http_error(self, mock_secret_client):
        """
        Edge case for :meth:`AzureKeyVaultHelper.get_responsive_url`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        """

        def list_properties_side_effect():
            client_call_url = mock_secret_client.call_args.kwargs["vault_url"]
            if "privatelink" in client_call_url:
                raise HttpResponseError("forbidden")
            return iter([1])

        mock_secret_client.return_value.list_properties_of_secrets.side_effect = (
            lambda: list_properties_side_effect()
        )
        helper = AzureKeyVaultHelper(vault_url="https://example.vault.azure.net")
        assert helper.vault_url == "https://example.vault.azure.net"

    def test_get_responsive_url_raises_ansible_error_when_no_endpoint_responsive(
        self, mock_secret_client
    ):
        """
        Edge case for :meth:`AzureKeyVaultHelper.get_responsive_url`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        """
        mock_secret_client.return_value.list_properties_of_secrets.side_effect = RuntimeError(
            "unreachable"
        )
        with pytest.raises(AnsibleError, match="Failed to connect to both"):
            AzureKeyVaultHelper(vault_url="https://example.vault.azure.net")

    def test_get_secret_returns_secret_value_on_success(self, mock_secret_client, mocker):
        """
        Happy path for :meth:`AzureKeyVaultHelper.get_secret`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        :param mocker: pytest-mock fixture used to build a fake secret result.
        """
        mock_secret_client.return_value.list_properties_of_secrets.return_value = iter([1])
        secret = SimpleNamespace(value="s3cr3t")
        mock_secret_client.return_value.get_secret.return_value = secret
        helper = AzureKeyVaultHelper(vault_url="https://example.vault.azure.net")
        result = helper.get_secret("my-secret")
        assert result == "s3cr3t"

    def test_get_secret_raises_ansible_error_on_failure(self, mock_secret_client):
        """
        Edge case for :meth:`AzureKeyVaultHelper.get_secret`.

        :param mock_secret_client: Fixture patching ``SecretClient``.
        """
        mock_secret_client.return_value.list_properties_of_secrets.return_value = iter([1])
        mock_secret_client.return_value.get_secret.side_effect = RuntimeError("not found")
        helper = AzureKeyVaultHelper(vault_url="https://example.vault.azure.net")
        with pytest.raises(AnsibleError, match="Failed to fetch secret"):
            helper.get_secret("my-secret")

    def test_lookup_module_run_returns_secret_values(self, mocker):
        """
        Happy path for :meth:`LookupModule.run`.

        :param mocker: pytest-mock fixture used to patch the helper class.
        """
        helper_instance = _StubKeyVaultHelper(["s1", "s2"])
        mocker.patch(f"{_MODULE}.AzureKeyVaultHelper", return_value=helper_instance)
        module = LookupModule()
        result = module.run(
            ["secret1", "secret2"],
            variables=None,
            vault_url="https://example.vault.azure.net",
        )
        assert result == ["s1", "s2"]

    def test_lookup_module_run_raises_when_vault_url_missing(self):
        """
        Edge case for :meth:`LookupModule.run`.

        Verifies that a missing ``vault_url`` raises an
        :class:`AnsibleError` before any helper is created.
        """
        module = LookupModule()
        with pytest.raises(AnsibleError, match="Failed to get a valid vault url"):
            module.run(["secret1"], variables=None)
