# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for the ``New-SDAFGitHubActions.py`` launcher script.
"""

import runpy
from pathlib import Path

_LAUNCHER_SCRIPT = str(
    Path(__file__).resolve().parents[5]
    / "deploy"
    / "scripts"
    / "py_scripts"
    / "SDAF-GitHub-Actions"
    / "New-SDAFGitHubActions.py"
)


class TestNewSdafGithubActionsLauncher:
    """
    Test suite covering the ``New-SDAFGitHubActions.py`` launcher script.
    """

    def test_launcher_invokes_main_when_run_as_script(self, mocker):
        """
        Happy path: running the launcher script as ``__main__`` calls
        :func:`sdaf.main.main` exactly once.

        :param mocker: pytest-mock fixture used to patch the ``main``
            callable re-exported from ``sdaf/__init__.py`` before the
            launcher script imports and executes it.
        """
        main_mock = mocker.patch("sdaf.main")
        runpy.run_path(_LAUNCHER_SCRIPT, run_name="__main__")
        main_mock.assert_called_once_with()
