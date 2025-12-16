import requests
import json
import time

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
            print(f"Skipping variable {variable_name} because it has an empty value.")
            continue
            
        try:
            repo.create_variable(variable_name, str(variable_value))
            print(f"*** Variable {variable_name} added to repository {repo_full_name}.***")
        except Exception as e:
            print(f"Error adding variable {variable_name}: {str(e)}")
            print("Continuing with other variables...")


def add_repository_secrets(github_client, repo_full_name, secrets):
    """
    Add secrets to the repository.
    """
    repo = github_client.get_repo(repo_full_name)
    for secret_name, secret_value in secrets.items():
        repo.create_secret(secret_name, secret_value)
        print(f"*** Secret {secret_name} added to {repo_full_name}.***")


def add_environment_secrets(github_client, repo_full_name, environment_name, secrets):
    """
    Add secrets to a specific environment in the repository.
    """
    repo = github_client.get_repo(repo_full_name)
    environment = repo.get_environment(environment_name)
    for secret_name, secret_value in secrets.items():
        # Skip empty values
        if secret_value is None or secret_value == "":
            print(f"Skipping secret {secret_name} because it has an empty value.")
            continue
            
        try:
            environment.create_secret(secret_name, secret_value)
            print(f"*** Secret {secret_name} added to environment {environment_name} in {repo_full_name}.***")
        except Exception as e:
            print(f"Error adding secret {secret_name}: {str(e)}")
            print("Continuing with other secrets...")


def add_environment_variables(github_client, repo_full_name, environment_name, variables):
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
            print(f"Skipping variable {variable_name} because it has an empty value.")
            continue
            
        try:
            environment.create_variable(variable_name, variable_value)
            print(
                f"*** Variable {variable_name} added to environment {environment_name} in {repo_full_name}.***"
            )
        except Exception as e:
            print(f"Error adding variable {variable_name}: {str(e)}")
            print("Continuing with other variables...")

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
        print("\nWARNING: Managed identity is enabled but identity_id is missing.")
        print("This may cause GitHub workflow to fail. Checking if we can construct the ID...")
        
        # Try to construct ID from components
        if all(user_data.get(k) for k in ["identity_name", "subscription_id", "resource_group"]):
            constructed_id = (
                f"/subscriptions/{user_data['subscription_id']}/"
                f"resourceGroups/{user_data['resource_group']}/"
                f"providers/Microsoft.ManagedIdentity/userAssignedIdentities/"
                f"{user_data['identity_name']}"
            )
            print(f"Constructed MSI ID: {constructed_id}")
            user_data["identity_id"] = constructed_id
        else:
            print("ERROR: Cannot construct MSI ID. Missing required components.")
            print("Please ensure identity_name, subscription_id, and resource_group are set.")
    
    # Prepare workflow inputs with safe dictionary access
    try:
        workflow_inputs = {
            "control_plane_name": user_data["control_plane_name"],
            "use_msi": "true" if user_data.get("use_managed_identity") else "false",
            "msi_id": user_data.get("identity_id", "") if user_data.get("use_managed_identity") else "",
        }
        
        # Validate MSI ID format if MSI is enabled
        if workflow_inputs["use_msi"] == "true" and workflow_inputs["msi_id"]:
            msi_id = workflow_inputs["msi_id"]
            msi_id_lower = msi_id.lower()  # normalize for validation only
            if not (msi_id_lower.startswith("/subscriptions/") and 
                    "resourcegroups/" in msi_id_lower and 
                    "microsoft.managedidentity/userassignedidentities/" in msi_id_lower):
                print(f"WARNING: MSI ID format may be invalid: {msi_id}")
                print("Expected format: /subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/...")
    except KeyError as e:
        print(f"ERROR: Missing required workflow input: {e}")
        return False
        
    data = {
        "ref": "main",
        "inputs": workflow_inputs
    }

    response = requests.post(url, headers=headers, data=json.dumps(data))

    if response.status_code == 204:
        print(f"Workflow '{workflow_id}' triggered successfully.")
        time.sleep(70)
        return True
    elif response.status_code == 401:
        print("ERROR: Authentication failed. Check your GitHub token permissions.")
        return False
    elif response.status_code == 404:
        print(f"ERROR: Workflow '{workflow_id}' or repository '{user_data['repo_name']}' not found.")
        print("Verify the workflow file exists and the repository name is correct.")
        return False
    elif response.status_code == 422:
        print("ERROR: Invalid workflow inputs or repository configuration.")
        try:
            error_details = response.json()
            print(f"Details: {error_details}")
        except:
            print(f"Response: {response.text}")
        return False
    else:
        print(f"ERROR: Failed to trigger workflow '{workflow_id}': HTTP {response.status_code}")
        try:
            error_details = response.json()
            print(f"Error details: {error_details}")
        except:
            print(f"Response: {response.text}")
        return False
