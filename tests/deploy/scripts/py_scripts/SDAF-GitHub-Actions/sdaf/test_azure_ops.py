# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for ``sdaf.azure_ops``.
"""

import json
import pytest
import sdaf.azure_ops


def _completed(returncode=0, stdout="", stderr=""):
    """
    Build a lightweight stand-in for ``subprocess.CompletedProcess``.

    :param returncode: The simulated process exit code.
    :param stdout: The simulated standard output text.
    :param stderr: The simulated standard error text.
    :return: An object exposing ``returncode``, ``stdout``, and ``stderr``.
    """

    class _Result:
        def __init__(self):
            self.returncode = returncode
            self.stdout = stdout
            self.stderr = stderr

    return _Result()


class TestAzureOps:
    """
    Test suite covering every public function of ``sdaf.azure_ops``.
    """

    def test_get_azure_oidc_config_returns_public_cloud_defaults(self, mocker):
        """The public Azure cloud uses the standard token-exchange audience."""
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout="AzureCloud\n"),
        )

        assert sdaf.azure_ops.get_azure_oidc_config() == {
            "environment": "AzureCloud",
            "audience": "api://AzureADTokenExchange",
        }

    def test_get_azure_oidc_config_returns_us_government_values(self, mocker):
        """Azure US Government uses its sovereign token-exchange audience."""
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout="AzureUSGovernment\n"),
        )

        assert sdaf.azure_ops.get_azure_oidc_config() == {
            "environment": "AzureUSGovernment",
            "audience": "api://AzureADTokenExchangeUSGov",
        }

    def test_get_azure_oidc_config_rejects_unknown_cloud(self, mocker):
        """Unknown clouds fail before creating a mismatched federated credential."""
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout="PrivateCloud\n"),
        )

        with pytest.raises(ValueError, match="PrivateCloud"):
            sdaf.azure_ops.get_azure_oidc_config()

    def test_get_azure_oidc_config_reports_cli_failure(self, mocker):
        """Azure CLI lookup failures stop bootstrap with the original diagnostic."""
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="not logged in"),
        )

        with pytest.raises(RuntimeError, match="not logged in"):
            sdaf.azure_ops.get_azure_oidc_config()

    def test_verify_azure_login_returns_true_when_logged_in(self, mocker):
        """
        Happy path for :func:`sdaf.azure_ops.verify_azure_login`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout="my-account\n"),
        )
        assert sdaf.azure_ops.verify_azure_login() is True

    def test_verify_azure_login_returns_false_when_not_logged_in(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.verify_azure_login`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="not logged in"),
        )
        assert sdaf.azure_ops.verify_azure_login() is False

    def test_verify_azure_login_returns_false_on_exception(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.verify_azure_login`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.run_az_command", side_effect=RuntimeError("boom"))
        assert sdaf.azure_ops.verify_azure_login() is False

    def test_verify_subscription_returns_true_when_subscription_set(self, mocker):
        """
        Happy path for :func:`sdaf.azure_ops.verify_subscription`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.run_az_command", return_value=_completed(returncode=0))
        assert sdaf.azure_ops.verify_subscription("sub-id") is True

    def test_verify_subscription_returns_false_when_subscription_set_fails(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.verify_subscription`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="not found"),
        )
        assert sdaf.azure_ops.verify_subscription("bad-sub") is False

    def test_verify_subscription_returns_false_on_exception(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.verify_subscription`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.run_az_command", side_effect=RuntimeError("boom"))
        assert sdaf.azure_ops.verify_subscription("sub-id") is False

    def test_verify_resource_group_returns_true_when_resource_group_exists(self, mocker):
        """
        Happy path for :func:`sdaf.azure_ops.verify_resource_group`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="my-sub\n"),
                _completed(returncode=0, stdout="true\n"),
            ],
        )
        assert sdaf.azure_ops.verify_resource_group("my-rg", "sub-id") is True

    def test_verify_resource_group_returns_false_when_subscription_inaccessible(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.verify_resource_group`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="no access"),
        )
        assert sdaf.azure_ops.verify_resource_group("my-rg", "bad-sub") is False

    def test_verify_resource_group_returns_false_when_resource_group_missing(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.verify_resource_group`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="my-sub\n"),
                _completed(returncode=0, stdout="false\n"),
            ],
        )
        assert sdaf.azure_ops.verify_resource_group("my-rg", "sub-id") is False

    def test_verify_resource_group_returns_false_on_exception(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.verify_resource_group`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.run_az_command", side_effect=RuntimeError("boom"))
        assert sdaf.azure_ops.verify_resource_group("my-rg", "sub-id") is False

    def test_create_user_assigned_identity_creates_identity_and_assigns_roles(self, mocker):
        """
        Happy path for :func:`sdaf.azure_ops.create_user_assigned_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        identity_json = json.dumps(
            {"id": "identity-id", "principalId": "principal-id", "clientId": "client-id"}
        )
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0),
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0, stdout="true\n"),
                _completed(returncode=0, stdout=identity_json),
                *[_completed(returncode=0, stdout="role-assignment-id\n") for _ in range(7)],
            ],
        )
        result = sdaf.azure_ops.create_user_assigned_identity(
            "my-identity", "my-rg", "sub-id", "westeurope"
        )
        assert result["name"] == "my-identity"
        assert result["identityId"] == "identity-id"
        assert result["principalId"] == "principal-id"
        assert len(result["roleAssignments"]) == 7

    def test_create_user_assigned_identity_returns_none_when_not_logged_in(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_user_assigned_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="not logged in"),
        )
        result = sdaf.azure_ops.create_user_assigned_identity(
            "my-identity", "my-rg", "sub-id", "westeurope"
        )
        assert result is None

    def test_create_user_assigned_identity_returns_none_when_subscription_verification_fails(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_user_assigned_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=1, stderr="bad sub"),
            ],
        )

        result = sdaf.azure_ops.create_user_assigned_identity(
            "my-identity", "my-rg", "sub-id", "westeurope"
        )

        assert result is None

    def test_create_user_assigned_identity_returns_none_when_resource_group_verification_fails(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_user_assigned_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0),
                _completed(returncode=1, stderr="no access"),
            ],
        )

        result = sdaf.azure_ops.create_user_assigned_identity(
            "my-identity", "my-rg", "sub-id", "westeurope"
        )

        assert result is None

    def test_create_user_assigned_identity_returns_none_when_identity_create_fails(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_user_assigned_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0),
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0, stdout="true\n"),
                _completed(returncode=1, stderr="create failed"),
            ],
        )

        result = sdaf.azure_ops.create_user_assigned_identity(
            "my-identity", "my-rg", "sub-id", "westeurope"
        )

        assert result is None

    def test_create_user_assigned_identity_reports_warning_when_some_roles_fail(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_user_assigned_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        identity_json = json.dumps(
            {"id": "identity-id", "principalId": "principal-id", "clientId": "client-id"}
        )
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0),
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0, stdout="true\n"),
                _completed(returncode=0, stdout=identity_json),
                _completed(returncode=1, stderr="denied"),
                *[_completed(returncode=0, stdout="role-id\n") for _ in range(6)],
            ],
        )

        result = sdaf.azure_ops.create_user_assigned_identity(
            "my-identity", "my-rg", "sub-id", "westeurope"
        )

        assert len(result["roleAssignments"]) == 6

    def test_create_user_assigned_identity_returns_none_on_unexpected_exception(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_user_assigned_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0),
                _completed(returncode=0, stdout="acct\n"),
                _completed(returncode=0, stdout="true\n"),
                _completed(returncode=0, stdout="not-json"),
            ],
        )
        result = sdaf.azure_ops.create_user_assigned_identity(
            "my-identity", "my-rg", "sub-id", "westeurope"
        )
        assert result is None

    def test_create_azure_service_principal_creates_new_service_principal(self, mocker):
        """
        Happy path for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        create_json = json.dumps({"appId": "app-id", "password": "pwd", "tenant": "tenant-id"})
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout=create_json),
                _completed(returncode=0, stdout=json.dumps({"id": "object-id"})),
                *[_completed(returncode=0) for _ in range(7)],
            ],
        )

        user_data = {
            "use_existing_spn": False,
            "spn_name": "my-spn",
            "subscription_id": "sub-id",
        }

        result = sdaf.azure_ops.create_azure_service_principal(user_data)

        assert result["appId"] == "app-id"
        assert result["object_id"] == "object-id"

    def test_create_azure_service_principal_uses_existing_service_principal(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``
            and ``diagnose_service_principal_issues``.
        """
        mocker.patch(
            "sdaf.azure_ops.diagnose_service_principal_issues",
            return_value=(True, "all good"),
        )
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout=json.dumps([{"roleDefinitionName": "Contributor"}]))
            ]
            * 7,
        )

        user_data = {
            "use_existing_spn": True,
            "spn_name": "existing-spn",
            "spn_appid": "existing-app-id",
            "spn_password": "",
            "spn_object_id": "",
            "subscription_id": "sub-id",
        }

        result = sdaf.azure_ops.create_azure_service_principal(user_data)

        assert result["appId"] == "existing-app-id"
        assert result["password"] == "PLACEHOLDER-CLIENT-SECRET"
        assert result["object_id"] == "PLACEHOLDER-OBJECT-ID"

    def test_create_azure_service_principal_existing_spn_missing_app_id_uses_placeholder(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch
            ``run_az_command`` and ``diagnose_service_principal_issues``.
        """
        mocker.patch(
            "sdaf.azure_ops.diagnose_service_principal_issues",
            return_value=(True, "all good"),
        )
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(
                returncode=0, stdout=json.dumps([{"roleDefinitionName": "Contributor"}])
            ),
        )

        user_data = {
            "use_existing_spn": True,
            "spn_name": "existing-spn",
            "spn_appid": "",
            "spn_password": "pwd",
            "spn_object_id": "object-id",
            "subscription_id": "sub-id",
        }

        result = sdaf.azure_ops.create_azure_service_principal(user_data)

        assert result["appId"] == "PLACEHOLDER-APP-ID"

    def test_create_azure_service_principal_existing_spn_reports_role_check_and_assignment_failures(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch
            ``run_az_command`` and ``diagnose_service_principal_issues``.
        """
        mocker.patch(
            "sdaf.azure_ops.diagnose_service_principal_issues",
            return_value=(True, "all good"),
        )
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=1, stderr="denied"),
                _completed(returncode=0, stdout="[]"),
                _completed(returncode=0, stdout="new-role-id\n"),
                _completed(returncode=0, stdout="not-json"),
                *[
                    _completed(returncode=0, stdout=json.dumps([{"roleDefinitionName": "x"}]))
                    for _ in range(4)
                ],
            ],
        )

        user_data = {
            "use_existing_spn": True,
            "spn_name": "existing-spn",
            "spn_appid": "existing-app-id",
            "spn_password": "pwd",
            "spn_object_id": "object-id",
            "subscription_id": "sub-id",
        }

        result = sdaf.azure_ops.create_azure_service_principal(user_data)
        assert result["appId"] == "existing-app-id"

    def test_create_azure_service_principal_existing_spn_role_assignment_command_fails(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch
            ``run_az_command`` and ``diagnose_service_principal_issues``.
        """
        mocker.patch(
            "sdaf.azure_ops.diagnose_service_principal_issues",
            return_value=(True, "all good"),
        )
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="[]"),
                _completed(returncode=1, stderr="denied"),
                *[
                    _completed(returncode=0, stdout=json.dumps([{"roleDefinitionName": "x"}]))
                    for _ in range(6)
                ],
            ],
        )

        user_data = {
            "use_existing_spn": True,
            "spn_name": "existing-spn",
            "spn_appid": "existing-app-id",
            "spn_password": "pwd",
            "spn_object_id": "object-id",
            "subscription_id": "sub-id",
        }

        result = sdaf.azure_ops.create_azure_service_principal(user_data)
        assert result["appId"] == "existing-app-id"

    def test_create_azure_service_principal_returns_none_when_create_for_rbac_fails(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="permission denied"),
        )

        user_data = {"use_existing_spn": False, "spn_name": "my-spn", "subscription_id": "sub-id"}

        result = sdaf.azure_ops.create_azure_service_principal(user_data)

        assert result is None

    def test_create_azure_service_principal_returns_none_when_create_for_rbac_output_malformed(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout="not-json"),
        )

        user_data = {"use_existing_spn": False, "spn_name": "my-spn", "subscription_id": "sub-id"}

        result = sdaf.azure_ops.create_azure_service_principal(user_data)

        assert result is None

    def test_create_azure_service_principal_uses_placeholder_object_id_when_sp_show_fails(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        create_json = json.dumps({"appId": "app-id", "password": "pwd"})
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout=create_json),
                _completed(returncode=1, stderr="not found"),
                *[_completed(returncode=0) for _ in range(7)],
            ],
        )

        user_data = {"use_existing_spn": False, "spn_name": "my-spn", "subscription_id": "sub-id"}
        result = sdaf.azure_ops.create_azure_service_principal(user_data)
        assert result["object_id"] == "PLACEHOLDER-OBJECT-ID"

    def test_create_azure_service_principal_uses_placeholder_object_id_when_sp_show_output_malformed(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        create_json = json.dumps({"appId": "app-id", "password": "pwd"})
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout=create_json),
                _completed(returncode=0, stdout="not-json"),
                *[_completed(returncode=0) for _ in range(7)],
            ],
        )

        user_data = {"use_existing_spn": False, "spn_name": "my-spn", "subscription_id": "sub-id"}

        result = sdaf.azure_ops.create_azure_service_principal(user_data)

        assert result["object_id"] == "PLACEHOLDER-OBJECT-ID"

    def test_create_azure_service_principal_new_spn_tracks_role_assignment_exceptions(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        create_json = json.dumps({"appId": "app-id", "password": "pwd"})
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout=create_json),
                _completed(returncode=0, stdout=json.dumps({"id": "object-id"})),
                RuntimeError("network blip"),
                *[_completed(returncode=0) for _ in range(6)],
            ],
        )

        user_data = {"use_existing_spn": False, "spn_name": "my-spn", "subscription_id": "sub-id"}
        result = sdaf.azure_ops.create_azure_service_principal(user_data)
        assert result["appId"] == "app-id"

    def test_create_azure_service_principal_new_spn_tracks_role_assignment_command_failures(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_azure_service_principal`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        create_json = json.dumps({"appId": "app-id", "password": "pwd"})
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout=create_json),
                _completed(returncode=0, stdout=json.dumps({"id": "object-id"})),
                _completed(returncode=1, stderr="denied"),
                *[_completed(returncode=0) for _ in range(6)],
            ],
        )

        user_data = {"use_existing_spn": False, "spn_name": "my-spn", "subscription_id": "sub-id"}
        result = sdaf.azure_ops.create_azure_service_principal(user_data)
        assert result["appId"] == "app-id"

    def test_configure_federated_identity_configures_federated_credential_successfully(
        self, mocker
    ):
        """
        Happy path for :func:`sdaf.azure_ops.configure_federated_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        run_mock = mocker.patch(
            "sdaf.azure_ops.run_az_command", return_value=_completed(returncode=0)
        )

        user_data = {
            "environment_name": "MGMT",
            "federated_subject": "repo:org/repo:environment:MGMT",
            "azure_audience": "api://AzureADTokenExchange",
        }
        spn_data = {"appId": "app-id"}

        sdaf.azure_ops.configure_federated_identity(user_data, spn_data)

        run_mock.assert_called_once()

    def test_configure_federated_identity_logs_warning_when_federated_credential_fails(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.configure_federated_identity`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="conflict"),
        )

        user_data = {
            "environment_name": "MGMT",
            "federated_subject": "repo:org/repo:environment:MGMT",
            "azure_audience": "api://AzureADTokenExchange",
        }
        spn_data = {"appId": "app-id"}

        sdaf.azure_ops.configure_federated_identity(user_data, spn_data)

    def test_diagnose_service_principal_issues_returns_success_when_all_roles_present(self, mocker):
        """
        Happy path for
        :func:`sdaf.azure_ops.diagnose_service_principal_issues`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        roles_json = json.dumps(
            [
                {"roleDefinitionName": "Contributor"},
                {"roleDefinitionName": "User Access Administrator"},
            ]
        )
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="{}"),
                _completed(returncode=0, stdout=roles_json),
            ],
        )

        success, diagnosis = sdaf.azure_ops.diagnose_service_principal_issues("app-id", "sub-id")

        assert success is True
        assert "look good" in diagnosis

    def test_diagnose_service_principal_issues_returns_failure_when_spn_does_not_exist(
        self, mocker
    ):
        """
        Edge case for
        :func:`sdaf.azure_ops.diagnose_service_principal_issues`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="not found"),
        )

        success, diagnosis = sdaf.azure_ops.diagnose_service_principal_issues(
            "bad-app-id", "sub-id"
        )

        assert success is False
        assert "does not exist" in diagnosis

    def test_diagnose_service_principal_issues_returns_failure_when_role_list_command_fails(
        self, mocker
    ):
        """
        Edge case for
        :func:`sdaf.azure_ops.diagnose_service_principal_issues`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="{}"),
                _completed(returncode=1, stderr="denied"),
            ],
        )

        success, diagnosis = sdaf.azure_ops.diagnose_service_principal_issues("app-id", "sub-id")

        assert success is False
        assert "Error checking subscription role assignments" in diagnosis

    def test_diagnose_service_principal_issues_returns_failure_when_no_roles_assigned(self, mocker):
        """
        Edge case for
        :func:`sdaf.azure_ops.diagnose_service_principal_issues`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="{}"),
                _completed(returncode=0, stdout="[]"),
            ],
        )

        success, diagnosis = sdaf.azure_ops.diagnose_service_principal_issues("app-id", "sub-id")

        assert success is False
        assert "no role assignments" in diagnosis

    def test_diagnose_service_principal_issues_reports_missing_recommended_roles(self, mocker):
        """
        Edge case for
        :func:`sdaf.azure_ops.diagnose_service_principal_issues`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        roles_json = json.dumps([{"roleDefinitionName": "Contributor"}])
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="{}"),
                _completed(returncode=0, stdout=roles_json),
            ],
        )
        success, diagnosis = sdaf.azure_ops.diagnose_service_principal_issues("app-id", "sub-id")
        assert success is True
        assert "look good" in diagnosis

    def test_diagnose_service_principal_issues_returns_failure_when_role_list_output_malformed(
        self, mocker
    ):
        """
        Edge case for
        :func:`sdaf.azure_ops.diagnose_service_principal_issues`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="{}"),
                _completed(returncode=0, stdout="not-json"),
            ],
        )

        success, diagnosis = sdaf.azure_ops.diagnose_service_principal_issues("app-id", "sub-id")

        assert success is False
        assert "Unable to parse role assignments" in diagnosis

    def test_get_current_subscription_info_returns_subscription_details_when_logged_in(
        self, mocker
    ):
        """
        Happy path for
        :func:`sdaf.azure_ops.get_current_subscription_info`.

        :param mocker: pytest-mock fixture used to patch
            ``verify_azure_login`` and ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(
                returncode=0, stdout=json.dumps({"name": "My Sub", "id": "sub-id"})
            ),
        )

        success, subscription_id, subscription_name = sdaf.azure_ops.get_current_subscription_info()

        assert success is True
        assert subscription_id == "sub-id"
        assert subscription_name == "My Sub"

    def test_get_current_subscription_info_returns_false_when_not_logged_in(self, mocker):
        """
        Edge case for
        :func:`sdaf.azure_ops.get_current_subscription_info`.

        :param mocker: pytest-mock fixture used to patch
            ``verify_azure_login``.
        """
        mocker.patch("sdaf.azure_ops.verify_azure_login", return_value=False)

        success, subscription_id, subscription_name = sdaf.azure_ops.get_current_subscription_info()

        assert success is False
        assert subscription_id is None
        assert subscription_name is None

    def test_get_current_subscription_info_returns_false_when_show_command_fails(self, mocker):
        """
        Edge case for
        :func:`sdaf.azure_ops.get_current_subscription_info`.

        :param mocker: pytest-mock fixture used to patch
            ``verify_azure_login`` and ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=1, stderr="denied"),
        )
        success, subscription_id, subscription_name = sdaf.azure_ops.get_current_subscription_info()
        assert success is False
        assert subscription_id is None
        assert subscription_name is None

    def test_get_current_subscription_info_returns_false_when_subscription_fields_missing(
        self, mocker
    ):
        """
        Edge case for
        :func:`sdaf.azure_ops.get_current_subscription_info`.

        :param mocker: pytest-mock fixture used to patch
            ``verify_azure_login`` and ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout=json.dumps({})),
        )
        success, subscription_id, subscription_name = sdaf.azure_ops.get_current_subscription_info()
        assert success is False
        assert subscription_id is None
        assert subscription_name is None

    def test_get_current_subscription_info_returns_false_when_output_malformed(self, mocker):
        """
        Edge case for
        :func:`sdaf.azure_ops.get_current_subscription_info`.

        :param mocker: pytest-mock fixture used to patch
            ``verify_azure_login`` and ``run_az_command``.
        """
        mocker.patch("sdaf.azure_ops.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout="not-json"),
        )
        success, subscription_id, subscription_name = sdaf.azure_ops.get_current_subscription_info()
        assert success is False
        assert subscription_id is None
        assert subscription_name is None

    def test_create_app_registration_returns_existing_app_registration_when_found(self, mocker):
        """
        Happy path for :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        existing = json.dumps({"appId": "existing-app-id", "id": "existing-object-id"})
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            return_value=_completed(returncode=0, stdout=existing),
        )
        result = sdaf.azure_ops.create_app_registration("MGMT-WEEU-DEP01-app")
        assert result == {"app_id": "existing-app-id", "object_id": "existing-object-id"}

    def test_create_app_registration_creates_new_app_registration_when_none_exists(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="null"),
                _completed(returncode=0, stdout="new-app-id\n"),
                _completed(
                    returncode=0,
                    stdout=json.dumps({"appId": "new-app-id", "id": "new-object-id"}),
                ),
            ],
        )
        result = sdaf.azure_ops.create_app_registration("MGMT-WEEU-DEP01-app")
        assert result == {"app_id": "new-app-id", "object_id": "new-object-id"}

    def test_create_app_registration_creates_new_when_existing_list_output_malformed(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="not-json"),
                _completed(returncode=0, stdout="new-app-id\n"),
                _completed(
                    returncode=0,
                    stdout=json.dumps({"appId": "new-app-id", "id": "new-object-id"}),
                ),
            ],
        )
        result = sdaf.azure_ops.create_app_registration("MGMT-WEEU-DEP01-app")
        assert result == {"app_id": "new-app-id", "object_id": "new-object-id"}

    def test_create_app_registration_includes_service_management_reference_when_provided(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        run_mock = mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="null"),
                _completed(returncode=0, stdout="new-app-id\n"),
                _completed(
                    returncode=0,
                    stdout=json.dumps({"appId": "new-app-id", "id": "new-object-id"}),
                ),
            ],
        )
        sdaf.azure_ops.create_app_registration(
            "MGMT-WEEU-DEP01-app", service_management_reference="ref-123"
        )
        create_call_args = run_mock.call_args_list[1].args[0]
        assert "--service-management-reference" in create_call_args
        assert "ref-123" in create_call_args

    def test_create_app_registration_returns_none_when_create_command_fails(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="null"),
                _completed(returncode=1, stderr="denied"),
            ],
        )
        result = sdaf.azure_ops.create_app_registration("MGMT-WEEU-DEP01-app")
        assert result is None

    def test_create_app_registration_uses_empty_object_id_when_final_lookup_output_malformed(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="null"),
                _completed(returncode=0, stdout="new-app-id\n"),
                _completed(returncode=0, stdout="not-json"),
            ],
        )
        result = sdaf.azure_ops.create_app_registration("MGMT-WEEU-DEP01-app")
        assert result == {"app_id": "new-app-id", "object_id": ""}

    def test_create_app_registration_returns_none_when_final_lookup_fails(self, mocker):
        """
        Edge case for :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch ``run_az_command``.
        """
        mocker.patch(
            "sdaf.azure_ops.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="null"),
                _completed(returncode=0, stdout="new-app-id\n"),
                _completed(returncode=1, stderr="denied"),
            ],
        )
        result = sdaf.azure_ops.create_app_registration("MGMT-WEEU-DEP01-app")
        assert result is None
