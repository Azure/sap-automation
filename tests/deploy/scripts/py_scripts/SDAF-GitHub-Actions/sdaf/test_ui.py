# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for ``sdaf.ui``.
"""

import json
import sys
import pytest
import sdaf.ui


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


class TestUi:
    """
    Test suite covering every public function of ``sdaf.ui``.
    """

    @staticmethod
    def _github_creation_prefix(repo_name, gh_app_name, gh_app_id, private_key_path, is_org="n"):
        """
        Build the common leading ``input()`` sequence shared by every
        :func:`sdaf.ui.get_user_input` scenario, covering GitHub App
        creation through installation confirmation.

        :param repo_name: The full ``owner/repository`` string to enter.
        :param gh_app_name: The GitHub App name to enter.
        :param gh_app_id: The GitHub App ID to enter.
        :param private_key_path: The path to the private key file to enter.
        :param is_org: The organization-account answer (``"y"`` or ``"n"``).
        :return: A list of input values matching the leading prompts.
        """
        prefix = [
            "",
            repo_name,
            "",
            "",
            gh_app_name,
            gh_app_id,
            private_key_path,
            is_org,
        ]
        if is_org in ["y", "yes"]:
            prefix.append("")
        prefix.append("")
        return prefix

    def test_display_instructions_prints_instructions_without_error(self, capsys):
        """
        Happy path for :func:`sdaf.ui.display_instructions`.

        :param capsys: pytest fixture used to capture stdout/stderr.
        """
        sdaf.ui.display_instructions()
        captured = capsys.readouterr()
        assert "This script helps you automate the setup" in captured.out

    def test_check_prerequisites_passes_when_tools_present_and_logged_in(self, mocker):
        """
        Happy path for :func:`sdaf.ui.check_prerequisites`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``,
            ``subprocess.run``, and ``verify_azure_login``.
        """
        mocker.patch("sdaf.ui.shutil.which", return_value="/usr/bin/az")
        mocker.patch(
            "sdaf.ui.subprocess.run",
            return_value=_completed(returncode=0, stdout="azure-cli 2.60.0"),
        )
        mocker.patch("sdaf.ui.verify_azure_login", return_value=True)
        sdaf.ui.check_prerequisites()

    def test_check_prerequisites_exits_when_azure_cli_missing(self, mocker):
        """
        Edge case for :func:`sdaf.ui.check_prerequisites`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``.
        """
        mocker.patch("sdaf.ui.shutil.which", return_value=None)

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.check_prerequisites()

        assert exc_info.value.code == 1

    def test_check_prerequisites_exits_when_user_declines_to_continue_without_login(self, mocker):
        """
        Edge case for :func:`sdaf.ui.check_prerequisites`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``,
            ``subprocess.run``, ``verify_azure_login``, and
            ``builtins.input``.
        """
        mocker.patch("sdaf.ui.shutil.which", return_value="/usr/bin/az")
        mocker.patch(
            "sdaf.ui.subprocess.run",
            return_value=_completed(returncode=0, stdout="azure-cli 2.60.0"),
        )
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch("builtins.input", return_value="n")
        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.check_prerequisites()
        assert exc_info.value.code == 1

    def test_check_prerequisites_exits_when_github_package_missing(self, mocker):
        """
        Edge case for :func:`sdaf.ui.check_prerequisites`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``,
            ``subprocess.run``, and force an ``ImportError`` for the
            ``github`` module.
        """
        mocker.patch("sdaf.ui.shutil.which", return_value="/usr/bin/az")
        mocker.patch(
            "sdaf.ui.subprocess.run",
            return_value=_completed(returncode=0, stdout="azure-cli 2.60.0"),
        )
        mocker.patch.dict(sys.modules, {"github": None})
        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.check_prerequisites()

        assert exc_info.value.code == 1

    def test_get_user_input_existing_service_principal_happy_path(self, mocker, tmp_path):
        """
        Happy path for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n")

        input_values = [
            "",
            "myorg/myrepo",
            "",
            "",
            "my-app",
            "12345",
            str(private_key_file),
            "n",
            "",
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "my-spn",
            "app-id-456",
            "n",
            "n",
            "",
            "n",
        ]
        getpass_values = ["gh-pat-token", "spn-client-secret"]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", side_effect=getpass_values)
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=0, stdout=json.dumps({"id": "object-id-789"})),
        )

        result = sdaf.ui.get_user_input()

        assert result["token"] == "gh-pat-token"
        assert result["repo_name"] == "myorg/myrepo"
        assert result["control_plane_name"] == "MGMT-WEEU-DEP01"
        assert result["subscription_id"] == "sub-id-123"
        assert result["tenant_id"] == "tenant-id-123"
        assert result["use_managed_identity"] is False
        assert result["use_existing_spn"] is True
        assert result["spn_appid"] == "app-id-456"
        assert result["spn_password"] == "spn-client-secret"
        assert result["spn_object_id"] == "object-id-789"
        assert result["docker_image"] == "ghcr.io/azure/sap-automation:main"
        assert result["use_webapp"] is False

    def test_get_user_input_managed_identity_existing_identity_path(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "private-key2.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\nxyz\n-----END PRIVATE KEY-----\n")

        input_values = [
            "",
            "myorg/otherrepo",
            "",
            "",
            "my-app-2",
            "54321",
            str(private_key_file),
            "n",
            "",
            "PROD-NOEU-DEP02",
            "y",
            "2",
            "y",
            "my-identity",
            "client-id-999",
            "identity-rg",
            "n",
            "new-spn-name",
            "n",
            "",
            "n",
        ]
        getpass_values = ["gh-pat-token-2"]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", side_effect=getpass_values)
        mocker.patch("sdaf.ui.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.ui.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="sub-auto-123\n"),
                _completed(returncode=0, stdout="tenant-auto-456\n"),
                _completed(
                    returncode=0,
                    stdout=json.dumps({"principalId": "p-id", "id": "identity-resource-id"}),
                ),
            ],
        )

        result = sdaf.ui.get_user_input()

        assert result["repo_name"] == "myorg/otherrepo"
        assert result["subscription_id"] == "sub-auto-123"
        assert result["tenant_id"] == "tenant-auto-456"
        assert result["use_managed_identity"] is True
        assert result["use_existing_identity"] is True
        assert result["identity_name"] == "my-identity"
        assert result["identity_principal_id"] == "p-id"
        assert result["identity_id"] == "identity-resource-id"
        assert result["use_existing_spn"] is False
        assert result["spn_name"] == "new-spn-name"

    def test_get_user_input_retries_private_key_path_after_read_errors(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``builtins.open``, ``getpass.getpass``, ``verify_azure_login``,
            and ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n")
        real_file = open(private_key_file, "r")

        mocker.patch(
            "builtins.open",
            side_effect=[
                FileNotFoundError(),
                PermissionError(),
                RuntimeError("disk error"),
                real_file,
            ],
        )

        input_values = self._github_creation_prefix(
            "myorg/myrepo", "my-app", "12345", "/bad/path-1"
        )
        input_values = (
            input_values[:7] + ["/bad/path-2", "/bad/path-3", "/bad/path-4"] + input_values[7:]
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "n",
            "new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)

        result = sdaf.ui.get_user_input()

        assert result["private_key"] == private_key_file.read_text()

    def test_get_user_input_org_account_prompts_for_public_app_setting(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "org-private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\norg\n-----END PRIVATE KEY-----\n")

        input_values = self._github_creation_prefix(
            "my-org/org-repo", "org-app", "99999", str(private_key_file), is_org="y"
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "n",
            "org-new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)

        result = sdaf.ui.get_user_input()

        assert result["repo_name"] == "my-org/org-repo"

    def test_get_user_input_validates_control_plane_name_format(self, mocker, tmp_path, capsys):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        :param capsys: pytest fixture used to capture stdout/stderr for
            validation-error assertions.
        """
        private_key_file = tmp_path / "cp-private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\ncp\n-----END PRIVATE KEY-----\n")

        input_values = self._github_creation_prefix(
            "myorg/cprepo", "cp-app", "11111", str(private_key_file)
        )
        input_values += [
            "BADFORMAT",
            "TOOLONGENV-WEEU-DEP01",
            "MGMT-WEEUX-DEP01",
            "MGMT-WEEU-TOOLONGVNET",
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "n",
            "cp-new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)

        result = sdaf.ui.get_user_input()

        captured = capsys.readouterr()
        assert result["control_plane_name"] == "MGMT-WEEU-DEP01"
        assert "must have format" in captured.out
        assert "must be maximum 5 characters" in captured.out
        assert "must be exactly 4 characters" in captured.out
        assert "VNet name" in captured.out

    def test_get_user_input_managed_identity_show_command_fails_exits(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "msi-private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\nmsi\n-----END PRIVATE KEY-----\n")

        input_values = self._github_creation_prefix(
            "myorg/msirepo", "msi-app", "22222", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "2",
            "y",
            "my-identity",
            "client-id-999",
            "identity-rg",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.ui.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="sub-auto-123\n"),
                _completed(returncode=0, stdout="tenant-auto-456\n"),
                _completed(returncode=1, stderr="not found"),
            ],
        )

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.get_user_input()

        assert exc_info.value.code == 1

    def test_get_user_input_managed_identity_show_output_malformed_exits(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "msi2-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nmsi2\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/msirepo2", "msi-app-2", "33333", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "2",
            "y",
            "my-identity-2",
            "client-id-888",
            "identity-rg-2",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.ui.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="sub-auto-123\n"),
                _completed(returncode=0, stdout="tenant-auto-456\n"),
                _completed(returncode=0, stdout="not-json"),
            ],
        )

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.get_user_input()

        assert exc_info.value.code == 1

    def test_get_user_input_managed_identity_new_identity_with_custom_resource_group(
        self, mocker, tmp_path
    ):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "msi3-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nmsi3\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/msirepo3", "msi-app-3", "44444", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "2",
            "n",
            "westeurope",
            "n",
            "my-custom-rg",
            "n",
            "msi-new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)

        result = sdaf.ui.get_user_input()

        assert result["resource_group"] == "my-custom-rg"
        assert result["use_managed_identity"] is True
        assert result["use_existing_identity"] is False

    def test_get_user_input_new_spn_generates_secret_with_password_key(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "spn1-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn1\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo1", "spn-app-1", "55555", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-1",
            "app-id-1",
            "y",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=0, stdout=json.dumps({"password": "new-secret-1"})),
        )

        result = sdaf.ui.get_user_input()

        assert result["spn_password"] == "new-secret-1"

    def test_get_user_input_new_spn_generates_secret_via_sp_fallback_with_credential_key(
        self, mocker, tmp_path
    ):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        Verifies that when ``az ad app credential reset`` fails, the
        fallback ``az ad sp credential reset`` is tried, and a
        ``credential`` key in the response is honored.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "spn2-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn2\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo2", "spn-app-2", "66666", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-2",
            "app-id-2",
            "y",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            side_effect=[
                _completed(returncode=1, stderr="app reset failed"),
                _completed(returncode=0, stdout=json.dumps({"credential": "new-secret-2"})),
            ],
        )

        result = sdaf.ui.get_user_input()

        assert result["spn_password"] == "new-secret-2"

    def test_get_user_input_new_spn_generates_secret_via_credentials_list_format(
        self, mocker, tmp_path
    ):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "spn3-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn3\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo3", "spn-app-3", "77777", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-3",
            "app-id-3",
            "y",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(
                returncode=0,
                stdout=json.dumps({"credentials": [{"password": "new-secret-3"}]}),
            ),
        )

        result = sdaf.ui.get_user_input()

        assert result["spn_password"] == "new-secret-3"

    def test_get_user_input_new_spn_secret_generation_fails_exits(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "spn4-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn4\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo4", "spn-app-4", "88888", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-4",
            "app-id-4",
            "y",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=1, stderr="denied"),
        )

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.get_user_input()

        assert exc_info.value.code == 1

    def test_get_user_input_new_spn_secret_response_malformed_exits(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "spn5-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn5\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo5", "spn-app-5", "99999", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-5",
            "app-id-5",
            "y",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=0, stdout=json.dumps({"unexpected": "field"})),
        )

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.get_user_input()

        assert exc_info.value.code == 1

    def test_get_user_input_new_spn_secret_response_malformed_does_not_print_stdout(
        self, mocker, tmp_path, capsys
    ):
        """
        Regression test for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        :param capsys: pytest fixture used to capture stdout/stderr.
        """
        private_key_file = tmp_path / "spn6-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn6\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo6", "spn-app-6", "99999", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-6",
            "app-id-6",
            "y",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(
                returncode=0,
                stdout=json.dumps({"unexpected": "SENTINEL-CLIENT-SECRET-VALUE"}),
            ),
        )

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.get_user_input()

        assert exc_info.value.code == 1
        assert "SENTINEL-CLIENT-SECRET-VALUE" not in capsys.readouterr().out

    def test_get_user_input_existing_spn_secret_show_command_fails_exits(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "spn6-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn6\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo6", "spn-app-6", "10101", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-6",
            "app-id-6",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", side_effect=["gh-pat-token", "existing-secret"])
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=1, stderr="not found"),
        )

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.get_user_input()

        assert exc_info.value.code == 1

    def test_get_user_input_existing_spn_secret_show_output_malformed_uses_placeholder(
        self, mocker, tmp_path
    ):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "spn7-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nspn7\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/spnrepo7", "spn-app-7", "11011", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-7",
            "app-id-7",
            "n",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", side_effect=["gh-pat-token", "existing-secret"])
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=0, stdout="not-json"),
        )

        result = sdaf.ui.get_user_input()

        assert result["spn_object_id"] == "PLACEHOLDER-OBJECT-ID"

    def test_get_user_input_collects_suser_credentials_and_webapp_name(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "webapp-private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\nweb\n-----END PRIVATE KEY-----\n")

        input_values = self._github_creation_prefix(
            "myorg/webapprepo", "webapp-app", "12121", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "n",
            "webapp-new-spn",
            "y",
            "s-user-name",
            "",
            "y",
            "custom-app-registration",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", side_effect=["gh-pat-token", "s-user-password"])
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)

        result = sdaf.ui.get_user_input()

        assert result["s_username"] == "s-user-name"
        assert result["s_password"] == "s-user-password"
        assert result["use_webapp"] is True
        assert result["app_registration_name"] == "custom-app-registration"

    def test_get_user_input_falls_back_to_manual_entry_when_auto_detection_fails(
        self, mocker, tmp_path
    ):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "auto-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nauto\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/autorepo", "auto-app", "13131", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "manual-sub-id",
            "manual-tenant-id",
            "1",
            "n",
            "auto-new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=0, stdout=""),
        )

        result = sdaf.ui.get_user_input()

        assert result["subscription_id"] == "manual-sub-id"
        assert result["tenant_id"] == "manual-tenant-id"

    def test_get_user_input_retries_when_auth_choice_invalid(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "authchoice-private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\nac\n-----END PRIVATE KEY-----\n")

        input_values = self._github_creation_prefix(
            "myorg/authchoicerepo", "authchoice-app", "14141", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "3",
            "1",
            "n",
            "authchoice-new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)

        result = sdaf.ui.get_user_input()

        assert result["auth_choice"] == "1"

    def test_get_user_input_retries_empty_custom_resource_group_name(self, mocker, tmp_path):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "emptyrg-private-key.pem"
        private_key_file.write_text("-----BEGIN PRIVATE KEY-----\nrg\n-----END PRIVATE KEY-----\n")

        input_values = self._github_creation_prefix(
            "myorg/emptyrgrepo", "emptyrg-app", "15151", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "2",
            "n",
            "westeurope",
            "n",
            "",
            "my-final-rg",
            "n",
            "emptyrg-new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)

        result = sdaf.ui.get_user_input()

        assert result["resource_group"] == "my-final-rg"

    def test_get_user_input_new_spn_secret_generation_yields_empty_password_exits(
        self, mocker, tmp_path
    ):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "emptysecret-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\nempty\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/emptysecretrepo", "emptysecret-app", "16161", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "sub-id-123",
            "tenant-id-123",
            "1",
            "y",
            "existing-spn-empty",
            "app-id-empty",
            "y",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=False)
        mocker.patch(
            "sdaf.ui.run_az_command",
            return_value=_completed(returncode=0, stdout=json.dumps({"password": ""})),
        )

        with pytest.raises(SystemExit) as exc_info:
            sdaf.ui.get_user_input()

        assert exc_info.value.code == 1

    def test_get_user_input_falls_back_to_manual_tenant_when_only_tenant_detection_fails(
        self, mocker, tmp_path
    ):
        """
        Edge case for :func:`sdaf.ui.get_user_input`.

        :param mocker: pytest-mock fixture used to patch ``builtins.input``,
            ``getpass.getpass``, ``verify_azure_login``, and
            ``run_az_command``.
        :param tmp_path: pytest fixture providing a temporary directory
            used to write a fake private key file.
        """
        private_key_file = tmp_path / "tenantonly-private-key.pem"
        private_key_file.write_text(
            "-----BEGIN PRIVATE KEY-----\ntenant\n-----END PRIVATE KEY-----\n"
        )

        input_values = self._github_creation_prefix(
            "myorg/tenantonlyrepo", "tenantonly-app", "17171", str(private_key_file)
        )
        input_values += [
            "MGMT-WEEU-DEP01",
            "y",
            "manual-tenant-only-id",
            "1",
            "n",
            "tenantonly-new-spn",
            "n",
            "",
            "n",
        ]

        mocker.patch("builtins.input", side_effect=input_values)
        mocker.patch("sdaf.ui.getpass.getpass", return_value="gh-pat-token")
        mocker.patch("sdaf.ui.verify_azure_login", return_value=True)
        mocker.patch(
            "sdaf.ui.run_az_command",
            side_effect=[
                _completed(returncode=0, stdout="sub-auto-only\n"),
                _completed(returncode=1, stderr="denied"),
            ],
        )

        result = sdaf.ui.get_user_input()

        assert result["subscription_id"] == "sub-auto-only"
        assert result["tenant_id"] == "manual-tenant-only-id"

    def test_check_prerequisites_notes_admin_privileges_on_windows(self, mocker):
        """
        Edge case for :func:`sdaf.ui.check_prerequisites`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``,
            ``subprocess.run``, ``verify_azure_login``, and
            ``platform.system``/``platform.release``.
        """
        mocker.patch("sdaf.ui.shutil.which", return_value="C:\\az.cmd")
        mocker.patch(
            "sdaf.ui.subprocess.run",
            return_value=_completed(returncode=0, stdout="azure-cli 2.60.0"),
        )
        mocker.patch("sdaf.ui.verify_azure_login", return_value=True)
        mocker.patch("sdaf.ui.platform.system", return_value="Windows")
        mocker.patch("sdaf.ui.platform.release", return_value="11")

        sdaf.ui.check_prerequisites()
