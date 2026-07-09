import logging
import requests
import json
import time

logger = logging.getLogger(__name__)


def add_repository_variables(github_client, repo_full_name, variables):
    """
    Add variables to the repository level.

    Args:
        github_client: The authenticated GitHub client
        repo_full_name: Full repository name (owner/repo)
        variables: Dictionary of variables to add as repository variables
                  (non-sensitive information that can be visible in logs)
    """
    repo = github_client.get_repo(repo_full_name)
    for variable_name, variable_value in variables.items():
        # Skip empty values
        if variable_value is None or variable_value == "":
            logger.info(
                "Skipping variable %s because it has an empty value.", variable_name
            )
            continue

        try:
            repo.create_variable(variable_name, str(variable_value))
            logger.info(
                "*** Variable %s added to repository %s.***",
                variable_name,
                repo_full_name,
            )
        except Exception as e:
            logger.error("Error adding variable %s: %s", variable_name, str(e))
            logger.info("Continuing with other variables...")


def add_repository_secrets(github_client, repo_full_name, secrets):
    """
    Add secrets to the repository.
    """
    repo = github_client.get_repo(repo_full_name)
    for secret_name, secret_value in secrets.items():
        repo.create_secret(secret_name, secret_value)
        logger.info("Secret added to %s", repo_full_name)


def add_environment_secrets(github_client, repo_full_name, environment_name, secrets):
    """
    Add secrets to a specific environment in the repository.
    """
    repo = github_client.get_repo(repo_full_name)
    environment = repo.get_environment(environment_name)
    for secret_name, secret_value in secrets.items():
        # Skip empty values
        if secret_value is None or secret_value == "":
            logger.debug("Skipping a secret with empty value in %s", environment_name)
            continue

        try:
            environment.create_secret(secret_name, secret_value)
            logger.info(
                "Secret added to environment %s in %s", environment_name, repo_full_name
            )
        except Exception as e:
            logger.error(
                "Error adding secret to environment %s: %s", environment_name, str(e)
            )
            logger.info("Continuing with other secrets...")


def add_environment_variables(
    github_client, repo_full_name, environment_name, variables
):
    """
    Add variables to a specific environment in the repository.

    Args:
        github_client: The authenticated GitHub client
        repo_full_name: Full repository name (owner/repo)
        environment_name: Name of the GitHub environment
        variables: Dictionary of variables to add as environment variables
                  (non-sensitive information that can be visible in logs)
    """
    repo = github_client.get_repo(repo_full_name)
    environment = repo.get_environment(environment_name)
    for variable_name, variable_value in variables.items():
        # GitHub API doesn't allow empty values for variables
        if variable_value is None or variable_value == "":
            logger.info(
                "Skipping variable %s because it has an empty value.", variable_name
            )
            continue

        try:
            environment.create_variable(variable_name, variable_value)
            logger.info(
                "*** Variable %s added to environment %s in %s.***",
                variable_name,
                environment_name,
                repo_full_name,
            )
        except Exception as e:
            logger.error("Error adding variable %s: %s", variable_name, str(e))
            logger.info("Continuing with other variables...")


def generate_repository_secrets(user_data, app_id, private_key):
    """
    Generate repository-level secrets.

    Args:
        user_data: User input data dictionary
        app_id: GitHub App ID
        private_key: Private key for the GitHub App

    Returns:
        Dictionary with repository secrets
    """
    return {
        "APPLICATION_ID": app_id,
        "APPLICATION_PRIVATE_KEY": private_key,
    }


def trigger_github_workflow(user_data, workflow_id):
    """
    Trigger a GitHub Actions workflow.
    """
    url = f"https://api.github.com/repos/{user_data['repo_name']}/actions/workflows/{workflow_id}/dispatches"
    headers = {
        "Authorization": f"token {user_data['token']}",
        "Accept": "application/vnd.github.v3+json",
    }
    if user_data.get("use_managed_identity") and not user_data.get("identity_id"):
        logger.warning("Managed identity is enabled but identity_id is missing.")
        logger.warning(
            "This may cause GitHub workflow to fail. Checking if we can construct the ID..."
        )

        # Try to construct ID from components
        if all(
            user_data.get(k)
            for k in ["identity_name", "subscription_id", "resource_group"]
        ):
            constructed_id = (
                f"/subscriptions/{user_data['subscription_id']}/"
                f"resourceGroups/{user_data['resource_group']}/"
                f"providers/Microsoft.ManagedIdentity/userAssignedIdentities/"
                f"{user_data['identity_name']}"
            )
            logger.info("Constructed MSI ID: %s", constructed_id)
            user_data["identity_id"] = constructed_id
        else:
            logger.error("Cannot construct MSI ID. Missing required components.")
            logger.error(
                "Please ensure identity_name, subscription_id, and resource_group are set."
            )

    # Prepare workflow inputs with safe dictionary access
    try:
        workflow_inputs = {
            "control_plane_name": user_data["control_plane_name"],
            "use_msi": "true" if user_data.get("use_managed_identity") else "false",
            "msi_id": (
                user_data.get("identity_id", "")
                if user_data.get("use_managed_identity")
                else ""
            ),
            "use_webapp": "true" if user_data.get("use_webapp") else "false",
        }

        # Validate MSI ID format if MSI is enabled
        if workflow_inputs["use_msi"] == "true" and workflow_inputs["msi_id"]:
            msi_id = workflow_inputs["msi_id"]
            msi_id_lower = msi_id.lower()  # normalize for validation only
            if not (
                msi_id_lower.startswith("/subscriptions/")
                and "resourcegroups/" in msi_id_lower
                and "microsoft.managedidentity/userassignedidentities/" in msi_id_lower
            ):
                logger.warning("MSI ID format may be invalid: %s", msi_id)
                logger.warning(
                    "Expected format: /subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/..."
                )
    except KeyError as e:
        logger.error("Missing required workflow input: %s", e)
        return False

    data = {"ref": "main", "inputs": workflow_inputs}

    response = requests.post(url, headers=headers, data=json.dumps(data))

    if response.status_code == 204:
        logger.info("Workflow '%s' triggered successfully.", workflow_id)
        time.sleep(70)
        return True
    elif response.status_code == 401:
        logger.error("Authentication failed. Check your GitHub token permissions.")
        return False
    elif response.status_code == 404:
        logger.error(
            "Workflow '%s' or repository '%s' not found.",
            workflow_id,
            user_data["repo_name"],
        )
        logger.error(
            "Verify the workflow file exists and the repository name is correct."
        )
        return False
    elif response.status_code == 422:
        logger.error("Invalid workflow inputs or repository configuration.")
        try:
            error_details = response.json()
            logger.error("Details: %s", error_details)
        except Exception:
            logger.error("Response: %s", response.text)
        return False
    else:
        logger.error(
            "Failed to trigger workflow '%s': HTTP %s",
            workflow_id,
            response.status_code,
        )
        try:
            error_details = response.json()
            logger.error("Error details: %s", error_details)
        except Exception:
            logger.error("Response: %s", response.text)
        return False
