# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for ``sdaf.github_ops``.
"""

from typing import Any
import pytest
import sdaf.github_ops


class _CallRecorder:
    """
    Minimal call-tracking callable used instead of ``unittest.mock``.

    :param return_value: The value returned for every invocation that
        is not overridden by :attr:`side_effect`.
    """

    def __init__(self, return_value: Any = None):
        self.calls: list = []
        self.return_value: Any = return_value
        self.side_effect: Any = None

    def __call__(self, *args, **kwargs):
        """
        Record the call and produce the configured result.

        :param args: Positional arguments passed by the caller.
        :param kwargs: Keyword arguments passed by the caller.
        :return: The configured ``return_value``, or the next item
            popped from :attr:`side_effect`.
        """
        self.calls.append((args, kwargs))
        if self.side_effect is not None:
            outcome = self.side_effect.pop(0)
            if isinstance(outcome, BaseException):
                raise outcome
            return outcome
        return self.return_value

    @property
    def call_count(self):
        """
        :return: The number of times this recorder has been called.
        """
        return len(self.calls)

    def assert_called_once(self):
        """
        Assert that this recorder was invoked exactly once.
        """
        assert self.call_count == 1, f"expected 1 call, got {self.call_count}"

    def assert_called_once_with(self, *args, **kwargs):
        """
        Assert a single call was made with the given arguments.

        :param args: Expected positional arguments.
        :param kwargs: Expected keyword arguments.
        """
        self.assert_called_once()
        assert self.calls[0] == (args, kwargs)

    def assert_any_call(self, *args, **kwargs):
        """
        Assert that at least one recorded call matches the given
        arguments.

        :param args: Expected positional arguments.
        :param kwargs: Expected keyword arguments.
        """
        assert (args, kwargs) in self.calls

    def assert_not_called(self):
        """
        Assert that this recorder was never invoked.
        """
        assert self.call_count == 0


class _FakeEnvironment:
    """
    Stand-in for a PyGithub ``Environment`` object.
    """

    def __init__(self):
        self.create_secret = _CallRecorder()
        self.create_variable = _CallRecorder()


class _FakeRepo:
    """
    Stand-in for a PyGithub ``Repository`` object.
    """

    def __init__(self):
        self.full_name = "org/repo"
        self.name = "repo"
        self.id = 200
        self.owner = type("Owner", (), {"login": "org", "id": 100})()
        self.create_variable = _CallRecorder()
        self.create_secret = _CallRecorder()
        self.get_environment = _CallRecorder(return_value=_FakeEnvironment())


class _FakeGithubClient:
    """
    Stand-in for a PyGithub ``Github`` client.
    """

    def __init__(self):
        self.get_repo = _CallRecorder(return_value=_FakeRepo())


class _FakeResponse:
    """
    Stand-in for a :class:`requests.Response` object.

    :param status_code: The simulated HTTP status code.
    :param text: The simulated raw response body text.
    :param json_result: The value returned by :meth:`json`.
    :param json_error: An exception instance to raise from
        :meth:`json` instead of returning ``json_result``.
    """

    def __init__(
        self, status_code: int, text: str = "", json_result: Any = None, json_error: Any = None
    ):
        self.status_code = status_code
        self.text = text
        self._json_result: Any = json_result
        self._json_error: Any = json_error

    def json(self):
        """
        :return: The configured ``json_result``.
        :raises Exception: The configured ``json_error``, when set.
        """
        if self._json_error is not None:
            raise self._json_error
        return self._json_result


class TestGithubOps:
    """
    Test suite covering every public function of ``sdaf.github_ops``.
    """

    @pytest.fixture(autouse=True)
    def _no_sleep(self, mocker):
        """
        Prevent the post-dispatch 70-second sleep from slowing down tests.

        :param mocker: pytest-mock fixture used to patch ``time.sleep``.
        """
        mocker.patch("sdaf.github_ops.time.sleep")

    def test_get_federated_subject_returns_immutable_subject_by_default(self):
        """GitHub Cloud repositories use immutable owner and repository IDs by default."""
        client = _FakeGithubClient()

        result = sdaf.github_ops.get_federated_subject(client, "org/repo", "MGMT")

        assert result == "repo:org@100/repo@200:environment:MGMT"

    def test_get_federated_subject_returns_standard_subject_when_requested(self):
        """Repositories without immutable subject claims retain the legacy format."""
        client = _FakeGithubClient()

        result = sdaf.github_ops.get_federated_subject(
            client, "org/repo", "MGMT", subject_format="standard"
        )

        assert result == "repo:org/repo:environment:MGMT"

    def test_get_federated_subject_honors_exact_override(self):
        """An explicit subject bypasses repository metadata lookup."""
        client = _FakeGithubClient()

        result = sdaf.github_ops.get_federated_subject(
            client,
            "org/repo",
            "MGMT",
            subject_override="repo:custom:environment:MGMT",
        )

        assert result == "repo:custom:environment:MGMT"
        client.get_repo.assert_not_called()

    def test_get_federated_subject_rejects_unknown_format(self):
        """Unknown subject formats fail before a credential is registered."""
        client = _FakeGithubClient()

        with pytest.raises(ValueError, match="standard.*immutable"):
            sdaf.github_ops.get_federated_subject(
                client, "org/repo", "MGMT", subject_format="unknown"
            )

    def test_add_repository_variables_adds_non_empty_variables(self, mocker):
        """
        Happy path for :func:`sdaf.github_ops.add_repository_variables`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value

        sdaf.github_ops.add_repository_variables(client, "org/repo", {"KEY": "value"})

        client.get_repo.assert_called_once_with("org/repo")
        repo.create_variable.assert_called_once_with("KEY", "value")

    def test_add_repository_variables_skips_empty_values_and_continues_on_error(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.add_repository_variables`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value
        repo.create_variable.side_effect = [Exception("boom"), None]

        sdaf.github_ops.add_repository_variables(
            client, "org/repo", {"EMPTY": "", "FAILS": "x", "OK": "y"}
        )

        assert repo.create_variable.call_count == 2

    def test_add_repository_secrets_adds_all_secrets(self, mocker):
        """
        Happy path for :func:`sdaf.github_ops.add_repository_secrets`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value

        sdaf.github_ops.add_repository_secrets(client, "org/repo", {"S1": "v1", "S2": "v2"})

        assert repo.create_secret.call_count == 2
        repo.create_secret.assert_any_call("S1", "v1")
        repo.create_secret.assert_any_call("S2", "v2")

    def test_add_environment_secrets_adds_non_empty_secrets_to_environment(self, mocker):
        """
        Happy path for :func:`sdaf.github_ops.add_environment_secrets`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value
        environment = repo.get_environment.return_value
        sdaf.github_ops.add_environment_secrets(client, "org/repo", "MGMT", {"SECRET": "value"})
        repo.get_environment.assert_called_once_with("MGMT")
        environment.create_secret.assert_called_once_with("SECRET", "value")

    def test_add_environment_secrets_skips_empty_secret_values(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.add_environment_secrets`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value
        environment = repo.get_environment.return_value

        sdaf.github_ops.add_environment_secrets(client, "org/repo", "MGMT", {"EMPTY": ""})

        environment.create_secret.assert_not_called()

    def test_add_environment_secrets_continues_when_secret_creation_fails(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.add_environment_secrets`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value
        environment = repo.get_environment.return_value
        environment.create_secret.side_effect = [Exception("boom"), None]

        sdaf.github_ops.add_environment_secrets(
            client, "org/repo", "MGMT", {"FAILS": "a", "OK": "b"}
        )

        assert environment.create_secret.call_count == 2

    def test_add_environment_variables_adds_non_empty_variables_to_environment(self, mocker):
        """
        Happy path for :func:`sdaf.github_ops.add_environment_variables`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value
        environment = repo.get_environment.return_value

        sdaf.github_ops.add_environment_variables(client, "org/repo", "MGMT", {"KEY": "value"})

        environment.create_variable.assert_called_once_with("KEY", "value")

    def test_add_environment_variables_skips_empty_variable_values(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.add_environment_variables`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value
        environment = repo.get_environment.return_value

        sdaf.github_ops.add_environment_variables(client, "org/repo", "MGMT", {"EMPTY": ""})

        environment.create_variable.assert_not_called()

    def test_add_environment_variables_continues_when_variable_creation_fails(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.add_environment_variables`.

        :param mocker: pytest-mock fixture used to build a fake GitHub
            client.
        """
        client = _FakeGithubClient()
        repo = client.get_repo.return_value
        environment = repo.get_environment.return_value
        environment.create_variable.side_effect = [Exception("boom"), None]

        sdaf.github_ops.add_environment_variables(
            client, "org/repo", "MGMT", {"FAILS": "a", "OK": "b"}
        )

        assert environment.create_variable.call_count == 2

    def test_generate_repository_secrets_returns_expected_secret_dict(self):
        """
        Happy path for :func:`sdaf.github_ops.generate_repository_secrets`.
        """
        result = sdaf.github_ops.generate_repository_secrets({}, "app-123", "private-key-data")

        assert result == {
            "APPLICATION_ID": "app-123",
            "APPLICATION_PRIVATE_KEY": "private-key-data",
        }

    def test_trigger_github_workflow_returns_true_on_successful_dispatch(self, mocker):
        """
        Happy path for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=204)
        post_mock = mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is True
        post_mock.assert_called_once()

    def test_trigger_github_workflow_returns_false_on_401_unauthorized(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=401)
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "bad-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is False

    def test_trigger_github_workflow_returns_false_when_required_input_missing(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        post_mock = mocker.patch("sdaf.github_ops.requests.post")

        user_data = {"repo_name": "org/repo", "token": "gh-token"}

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is False
        post_mock.assert_not_called()

    def test_trigger_github_workflow_constructs_msi_id_when_missing_components_present(
        self, mocker
    ):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=204)
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
            "use_managed_identity": True,
            "identity_name": "my-identity",
            "subscription_id": "sub-id",
            "resource_group": "my-rg",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is True
        assert user_data["identity_id"] == (
            "/subscriptions/sub-id/resourceGroups/my-rg/providers/"
            "Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"
        )

    def test_trigger_github_workflow_logs_error_when_msi_components_missing(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=204)
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
            "use_managed_identity": True,
            "identity_name": "my-identity",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is True
        assert "identity_id" not in user_data

    def test_trigger_github_workflow_warns_on_malformed_msi_id_format(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=204)
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
            "use_managed_identity": True,
            "identity_id": "not-a-valid-resource-id",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is True

    def test_trigger_github_workflow_returns_false_on_404_not_found(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=404)
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is False

    def test_trigger_github_workflow_returns_false_on_422_with_json_error_body(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=422, json_result={"message": "Invalid inputs"})
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is False

    def test_trigger_github_workflow_returns_false_on_422_with_non_json_body(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(status_code=422, text="not json", json_error=ValueError("no JSON"))
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
        }

        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")

        assert result is False

    def test_trigger_github_workflow_returns_false_on_unhandled_status_code(self, mocker):
        """
        Edge case for :func:`sdaf.github_ops.trigger_github_workflow`.

        :param mocker: pytest-mock fixture used to patch ``requests.post``.
        """
        response = _FakeResponse(
            status_code=500, text="server error", json_error=ValueError("no JSON")
        )
        mocker.patch("sdaf.github_ops.requests.post", return_value=response)

        user_data = {
            "repo_name": "org/repo",
            "token": "gh-token",
            "control_plane_name": "MGMT-WEEU-DEP01",
        }
        result = sdaf.github_ops.trigger_github_workflow(user_data, "deploy.yml")
        assert result is False
