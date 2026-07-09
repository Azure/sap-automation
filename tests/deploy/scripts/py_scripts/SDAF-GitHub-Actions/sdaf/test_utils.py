# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for ``sdaf.utils``.
"""

import subprocess
import pytest
from sdaf.utils import _redact_command, run_az_command


class TestUtils:
    """
    Test suite covering every public function of ``sdaf.utils``.
    """

    def test_redact_command_redacts_sensitive_flag_and_its_following_value(self):
        """
        Happy path for :func:`sdaf.utils._redact_command`.
        """
        cmd = ["az", "ad", "sp", "create-for-rbac", "--password", "hunter2"]
        result = _redact_command(cmd)
        assert result == ["az", "ad", "sp", "create-for-rbac", "***", "***"]

    def test_redact_command_redacts_flag_equals_value_form_when_flag_name_sensitive(self):
        """
        Edge case for :func:`sdaf.utils._redact_command`.
        """
        cmd = ["az", "keyvault", "generic-update", "--token=abc123"]
        result = _redact_command(cmd)
        assert result == ["az", "keyvault", "generic-update", "--token=***"]

    def test_redact_command_flag_equals_value_form_untouched_when_flag_name_not_sensitive(self):
        """
        Edge case for :func:`sdaf.utils._redact_command`.
        """
        cmd = ["az", "keyvault", "generic-update", "--name=my-resource"]
        result = _redact_command(cmd)
        assert result == cmd

    def test_redact_command_leaves_non_sensitive_arguments_untouched(self):
        """
        Edge case for :func:`sdaf.utils._redact_command`.
        """
        cmd = ["az", "group", "show", "--name", "my-rg"]
        result = _redact_command(cmd)
        assert result == cmd

    def test_run_az_command_runs_command_and_returns_completed_process(self, mocker):
        """
        Happy path for :func:`sdaf.utils.run_az_command`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``
            and ``subprocess.run``.
        """
        mocker.patch("sdaf.utils.shutil.which", return_value="/usr/bin/az")
        expected = subprocess.CompletedProcess(
            args=["/usr/bin/az", "group", "show"], returncode=0, stdout="{}", stderr=""
        )
        run_mock = mocker.patch("sdaf.utils.subprocess.run", return_value=expected)
        result = run_az_command(["group", "show"])
        run_mock.assert_called_once()
        assert result is expected

    def test_run_az_command_raises_file_not_found_when_az_cli_missing(self, mocker):
        """
        Edge case for :func:`sdaf.utils.run_az_command`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``.
        """
        mocker.patch("sdaf.utils.shutil.which", return_value=None)
        with pytest.raises(FileNotFoundError, match="Azure CLI not found"):
            run_az_command(["group", "show"])

    def test_run_az_command_returns_fake_completed_process_on_subprocess_not_found(self, mocker):
        """
        Edge case for :func:`sdaf.utils.run_az_command`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``
            and ``subprocess.run``.
        """
        mocker.patch("sdaf.utils.shutil.which", return_value="/usr/bin/az")
        mocker.patch("sdaf.utils.subprocess.run", side_effect=FileNotFoundError("not found"))
        result = run_az_command(["group", "show"], check=False)
        assert result.returncode == 127
        assert "Command not found" in result.stderr

    def test_run_az_command_reraises_when_check_true_and_command_missing(self, mocker):
        """
        Edge case for :func:`sdaf.utils.run_az_command`.

        :param mocker: pytest-mock fixture used to patch ``shutil.which``
            and ``subprocess.run``.
        """
        mocker.patch("sdaf.utils.shutil.which", return_value="/usr/bin/az")
        mocker.patch("sdaf.utils.subprocess.run", side_effect=FileNotFoundError("not found"))
        with pytest.raises(FileNotFoundError):
            run_az_command(["group", "show"], check=True)
