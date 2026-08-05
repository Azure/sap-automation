# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for ``sdaf.main``.
"""

import importlib
import pytest
from github import GithubException
import json as json_module

_main_module = importlib.import_module("sdaf.main")
run_main = _main_module.main


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


def _spn_data():
    """
    Build a fake Service Principal payload as returned by
    :func:`sdaf.azure_ops.create_azure_service_principal`.

    :return: A dictionary with the keys ``appId``, ``object_id``, and
        ``password``.
    """
    return {
        "appId": "app-id-123",
        "object_id": "object-id-456",
        "password": "spn-secret",
    }


def _user_data():
    """
    Build a minimal ``user_data`` dictionary for a Service-Principal-only,
    non-webapp, non-managed-identity run of :func:`sdaf.main.main`.

    :return: A dictionary of user input values as produced by
        :func:`sdaf.ui.get_user_input`.
    """
    return {
        "token": "gh-token",
        "repo_name": "org/repo",
        "gh_app_id": "app-123",
        "private_key": "private-key-data",
        "docker_image": "ghcr.io/azure/sap-automation:main",
        "subscription_id": "sub-id",
        "tenant_id": "tenant-id",
        "s_username": "",
        "s_password": "",
        "spn_name": "my-spn",
        "use_existing_spn": True,
        "server_url": "https://github.com",
        "auth_choice": "1",
        "control_plane_name": "MGMT-WEEU-DEP01",
    }


def _identity_data():
    """
    Build a fake Managed Identity payload as returned by
    :func:`sdaf.azure_ops.create_user_assigned_identity`.

    :return: A dictionary with identity metadata fields.
    """
    return {
        "name": "my-identity",
        "resourceGroup": "my-rg",
        "subscriptionId": "sub-id",
        "identityId": "identity-resource-id",
        "principalId": "principal-id-123",
        "clientId": "client-id-456",
        "roleAssignments": [],
    }


def _msi_user_data(use_existing_identity=True):
    """
    Build a minimal ``user_data`` dictionary for a Managed-Identity run
    of :func:`sdaf.main.main`.

    :param use_existing_identity: Whether to simulate reusing an
        existing Managed Identity (``True``) or creating a new one
        (``False``).
    :return: A dictionary of user input values as produced by
        :func:`sdaf.ui.get_user_input`.
    """
    data = _user_data()
    data["auth_choice"] = "2"
    data["use_managed_identity"] = True
    data["resource_group"] = "my-rg"
    data["region_map"] = "westeurope"
    data["environment"] = "MGMT"
    data["use_existing_identity"] = use_existing_identity
    if use_existing_identity:
        data["identity_name"] = "my-identity"
        data["identity_client_id"] = "client-id-456"
        data["identity_principal_id"] = "principal-id-123"
        data["identity_id"] = "identity-resource-id"
    return data


class TestMain:
    """
    Test suite covering :func:`sdaf.main.main`.
    """

    @pytest.fixture(autouse=True)
    def _mock_oidc_configuration(self, mocker):
        """Use deterministic cloud and repository OIDC values in every main-flow test."""
        mocker.patch(
            "sdaf.azure_ops.get_azure_oidc_config",
            return_value={
                "environment": "AzureCloud",
                "audience": "api://AzureADTokenExchange",
                "terraform_environment": "public",
            },
        )
        mocker.patch(
            "sdaf.github_ops.get_federated_subject",
            return_value="repo:org/repo:environment:MGMT-WEEU-DEP01",
        )

    def test_main_completes_successfully_for_service_principal_happy_path(self, mocker):
        """
        Happy path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main`` (``ui``, ``azure_ops``,
            ``github_ops``, and ``github.Github``).
        """
        user_data = _user_data()
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        trigger_mock = mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        add_environment_variables_mock = mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        run_main()

        trigger_mock.assert_called_once_with(user_data, "00-create-environment.yml")
        environment_variables = add_environment_variables_mock.call_args.args[3]
        assert environment_variables["ARM_ENVIRONMENT"] == "public"
        assert environment_variables["AZURE_ENVIRONMENT"] == "AzureCloud"
        assert environment_variables["AZURE_AUDIENCE"] == "api://AzureADTokenExchange"

    def test_main_exits_before_provisioning_for_invalid_oidc_subject_format(self, mocker):
        """Invalid OIDC format configuration must not create Azure resources."""
        user_data = _user_data()
        user_data["federated_subject_format"] = "unknown"
        create_spn_mock = mocker.patch("sdaf.azure_ops.create_azure_service_principal")

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1
        create_spn_mock.assert_not_called()

    def test_main_exits_when_repository_secret_creation_raises_github_exception(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main`` (``ui``, ``azure_ops``,
            ``github_ops``, and ``github.Github``).
        """
        user_data = _user_data()
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch(
            "sdaf.github_ops.add_repository_secrets",
            side_effect=GithubException(401, data={"message": "Bad credentials"}, headers={}),
        )

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_exits_when_repository_secret_creation_raises_404(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _user_data()
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch(
            "sdaf.github_ops.add_repository_secrets",
            side_effect=GithubException(404, data={"message": "Not Found"}, headers={}),
        )

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_exits_when_repository_secret_creation_raises_generic_error(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _user_data()
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch(
            "sdaf.github_ops.add_repository_secrets",
            side_effect=GithubException(500, data={"message": "Server Error"}, headers={}),
        )

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_exits_when_service_principal_creation_fails(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _user_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=None)

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_creates_temporary_spn_with_default_name_when_none_provided(self, mocker):
        """
        Edge case for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main`` and ``builtins.input``.
        """
        user_data = _user_data()
        user_data["spn_name"] = ""
        user_data["use_existing_spn"] = False
        user_data["environment"] = "MGMT"
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("builtins.input", return_value="y")
        create_spn_mock = mocker.patch(
            "sdaf.azure_ops.create_azure_service_principal", return_value=spn_data
        )
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        run_main()

        spn_user_data_arg = create_spn_mock.call_args_list[0].args[0]
        assert spn_user_data_arg["spn_name"] == "MGMT-SDAF-SPN"

    def test_main_creates_temporary_spn_with_custom_name_when_default_declined(self, mocker):
        """
        Edge case for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main`` and ``builtins.input``.
        """
        user_data = _user_data()
        user_data["spn_name"] = ""
        user_data["use_existing_spn"] = False
        user_data["environment"] = "MGMT"
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("builtins.input", side_effect=["n", "my-custom-temp-spn"])
        create_spn_mock = mocker.patch(
            "sdaf.azure_ops.create_azure_service_principal", return_value=spn_data
        )
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        run_main()

        spn_user_data_arg = create_spn_mock.call_args_list[0].args[0]
        assert spn_user_data_arg["spn_name"] == "my-custom-temp-spn"

    def test_main_creates_new_resource_group_when_missing_for_managed_identity(self, mocker):
        """
        Edge case for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=False)
        spn_data = _spn_data()
        identity_data = _identity_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=False)
        run_az_mock = mocker.patch.object(
            _main_module, "run_az_command", return_value=_completed(returncode=0)
        )
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.create_user_assigned_identity", return_value=identity_data)
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        run_main()

        run_az_mock.assert_called_once()
        create_call_args = run_az_mock.call_args.args[0]
        assert "create" in create_call_args

    def test_main_exits_when_resource_group_creation_fails_for_managed_identity(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=False)

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=False)
        mocker.patch.object(
            _main_module,
            "run_az_command",
            return_value=_completed(returncode=1, stderr="denied"),
        )

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_managed_identity_new_identity_full_flow_with_webapp(self, mocker):
        """
        Happy path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=False)
        user_data["use_webapp"] = True
        user_data["app_registration_name"] = "MGMT-app"
        spn_data = _spn_data()
        identity_data = _identity_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.create_user_assigned_identity", return_value=identity_data)
        mocker.patch(
            "sdaf.azure_ops.create_app_registration",
            return_value={"app_id": "webapp-app-id", "object_id": "webapp-object-id"},
        )
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        run_main()

    def test_main_passes_service_management_reference_to_app_registration(self, mocker):
        """
        Verify :func:`sdaf.main.main` forwards the collected service management
        reference to :func:`sdaf.azure_ops.create_app_registration`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=False)
        user_data["use_webapp"] = True
        user_data["app_registration_name"] = "MGMT-app"
        user_data["service_management_reference"] = "92a421fe-9780-4c8d-97d1-d5e9c4122bc5"
        spn_data = _spn_data()
        identity_data = _identity_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.create_user_assigned_identity", return_value=identity_data)
        create_app_registration = mocker.patch(
            "sdaf.azure_ops.create_app_registration",
            return_value={"app_id": "webapp-app-id", "object_id": "webapp-object-id"},
        )
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        run_main()

        create_app_registration.assert_called_once_with(
            "MGMT-app", "92a421fe-9780-4c8d-97d1-d5e9c4122bc5"
        )

    def test_main_exits_when_new_managed_identity_creation_fails(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=False)
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.create_user_assigned_identity", return_value=None)

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_managed_identity_existing_identity_full_flow_with_role_assignment_mix(
        self, mocker
    ):
        """
        Happy path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=True)
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        mocker.patch("builtins.input", return_value="y")
        mocker.patch.object(
            _main_module,
            "run_az_command",
            side_effect=[
                _completed(
                    returncode=0,
                    stdout=json_module.dumps({"clientId": "different-client-id"}),
                ),
                _completed(returncode=0, stdout=json_module.dumps([{"roleDefinitionName": "x"}])),
                _completed(returncode=0, stdout="[]"),
                _completed(returncode=1, stderr="assign denied"),
                _completed(returncode=1, stderr="denied"),
                _completed(returncode=0, stdout="not-json"),
                *[
                    _completed(
                        returncode=0, stdout=json_module.dumps([{"roleDefinitionName": "x"}])
                    )
                    for _ in range(3)
                ],
            ],
        )

        run_main()

    def test_main_exits_when_managed_identity_show_command_fails(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=True)
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch.object(
            _main_module,
            "run_az_command",
            return_value=_completed(returncode=1, stderr="not found"),
        )

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_exits_when_client_id_mismatch_declined(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=True)
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("builtins.input", return_value="n")

        mocker.patch.object(
            _main_module,
            "run_az_command",
            return_value=_completed(
                returncode=0, stdout=json_module.dumps({"clientId": "different-client-id"})
            ),
        )
        with pytest.raises(SystemExit) as exc_info:
            run_main()
        assert exc_info.value.code == 1

    def test_main_managed_identity_show_output_malformed_still_continues(self, mocker):
        """
        Edge case for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _msi_user_data(use_existing_identity=True)
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        mocker.patch.object(
            _main_module,
            "run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="not-json"),
                *[_completed(returncode=1, stderr="denied") for _ in range(7)],
            ],
        )

        run_main()

    def test_main_exits_when_workflow_trigger_fails(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _user_data()
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=False)

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_exits_when_environment_variable_update_raises_github_exception_404(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _user_data()
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch(
            "sdaf.github_ops.add_environment_variables",
            side_effect=GithubException(404, data={"message": "Not Found"}, headers={}),
        )

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_webapp_enabled_but_app_registration_creation_fails(self, mocker):
        """
        Edge case for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _user_data()
        user_data["use_webapp"] = True
        user_data["app_registration_name"] = "MGMT-app"
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.create_app_registration", return_value=None)
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")

        run_main()

    def test_main_exits_when_service_principal_configuration_fails(self, mocker):
        """
        Failure path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main``.
        """
        user_data = _user_data()
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch(
            "sdaf.azure_ops.create_azure_service_principal",
            side_effect=[spn_data, None],
        )

        with pytest.raises(SystemExit) as exc_info:
            run_main()

        assert exc_info.value.code == 1

    def test_main_managed_identity_full_flow_reports_temporary_spn_name(self, mocker):
        """
        Happy path for :func:`sdaf.main.main`.

        :param mocker: pytest-mock fixture used to patch every
            collaborator of ``sdaf.main`` and ``builtins.input``.
        """
        user_data = _msi_user_data(use_existing_identity=True)
        user_data["spn_name"] = ""
        user_data["use_existing_spn"] = False
        spn_data = _spn_data()

        mocker.patch("sdaf.ui.display_instructions")
        mocker.patch("sdaf.ui.check_prerequisites")
        mocker.patch("sdaf.ui.get_user_input", return_value=user_data)
        mocker.patch("sdaf.azure_ops.verify_resource_group", return_value=True)
        mocker.patch("builtins.input", return_value="y")
        mocker.patch("sdaf.azure_ops.create_azure_service_principal", return_value=spn_data)
        mocker.patch("sdaf.azure_ops.configure_federated_identity")
        mocker.patch.object(_main_module, "Github")
        mocker.patch("sdaf.github_ops.generate_repository_secrets", return_value={})
        mocker.patch("sdaf.github_ops.add_repository_secrets")
        mocker.patch("sdaf.github_ops.add_repository_variables")
        mocker.patch("sdaf.github_ops.trigger_github_workflow", return_value=True)
        mocker.patch("sdaf.github_ops.add_environment_variables")
        mocker.patch("sdaf.github_ops.add_environment_secrets")
        mocker.patch.object(
            _main_module,
            "run_az_command",
            return_value=_completed(returncode=0, stdout="{}"),
        )

        capture = mocker.patch("builtins.print")

        run_main()

        printed = " ".join(str(call.args[0]) for call in capture.call_args_list if call.args)
        assert (
            "Service Principal for initial GitHub Actions authentication has been created"
            in printed
        )
