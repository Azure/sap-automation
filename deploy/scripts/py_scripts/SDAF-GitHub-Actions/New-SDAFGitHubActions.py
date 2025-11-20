import requests
import json
import getpass
import os
import subprocess
import platform
import sys
import time
import shutil
from github import Github

def run_az_command(args, capture_output=True, check=False, text=True):
    """
    Run an Azure CLI command with improved cross-platform compatibility.

    Args:
        args: List of arguments to pass to the az command
        capture_output: Whether to capture stdout/stderr
        check: Whether to raise an exception on non-zero exit
        text: Whether to decode output as text

    Returns:
        A CompletedProcess instance with attributes:
        - args: The command arguments
        - returncode: The exit code
        - stdout: The captured stdout (if capture_output=True)
        - stderr: The captured stderr (if capture_output=True)
    """
    # Find Azure CLI executable with cross-platform support
    exe = shutil.which("az") or shutil.which("az.cmd")
    if not exe:
        raise FileNotFoundError("Azure CLI not found in PATH. Install or add to PATH.")

    cmd = [exe] + args

    # Run the command
    try:
        if capture_output:
            result = subprocess.run(cmd, capture_output=True, check=check, text=text)
        else:
            result = subprocess.run(cmd, check=check, text=text)

        return result
    except FileNotFoundError as e:
        print(f"Error: Azure CLI command not found. Make sure Azure CLI is installed and in your PATH.")
        print(f"Attempted to run: {' '.join(cmd)}")
        if check:
            raise e
        # Create a fake CompletedProcess to mimic the expected return type
        class FakeCompletedProcess:
            def __init__(self):
                self.returncode = 127  # Standard "command not found" error code
                self.args = cmd
                self.stdout = ""
                self.stderr = f"Command not found: {cmd[0]}"
        return FakeCompletedProcess()

def check_prerequisites():
    """
    Check if the necessary tools are available, particularly the Azure CLI and required Python packages.
    """
    print("\nChecking prerequisites...\n")

    # Check Azure CLI
    try:
        exe = shutil.which("az") or shutil.which("az.cmd")
        if not exe:
            raise FileNotFoundError("Azure CLI not found in PATH.")
        # Check if Azure CLI is installed and working
        print("Azure CLI found. Checking version...")
        cmd = [exe, "--version"]
        version_result = subprocess.run(cmd, capture_output=True, check=True, universal_newlines=True)
        print("Azure CLI is installed.")
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("Azure CLI not found. Please install it:")
        instructions = {
            "Windows": "https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows",
            "macOS"  : "https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos",
            "Linux"  : "https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux"
        }
        system = platform.system().lower()
        print(instructions.get(system, "Visit Azure CLI installation docs."))
        sys.exit(1)

    # Check Python packages
    try:
        import github
        print("Required Python packages are installed.")
    except ImportError:
        print("Missing Python dependency. Please run: pip install requests PyGithub")
        sys.exit(1)

    print(f"Running on {platform.system()} {platform.release()}")
    if platform.system().lower() == "windows":
        print("Note: On Windows, run the script with administrator privileges if needed.")

    # Verify Azure CLI login status but don't enforce login
    is_logged_in = verify_azure_login()
    if not is_logged_in:
        print("\nWARNING: You are not logged in to Azure CLI.")
        print("Please run 'az login' in a terminal before proceeding with Azure operations.")
        print("You can continue setting up GitHub App, but Azure operations will fail if not logged in.")
        choice = input("Do you want to continue without logging in to Azure? (y/n): ")
        if choice.lower() not in ["y", "yes"]:
            print("Exiting. Please run 'az login' and then restart this script.")
            sys.exit(1)

def display_instructions():
    print("""
        This script helps you automate the setup of a GitHub App, repository secrets,
        and environment for deploying SAP Deployment Automation Framework on Azure.

        Please follow these steps before running the script:
        1. Keep your repository name and owner ready.
        2. Be prepared to generate and download a private key for the GitHub App.
        """)

def get_user_input():
    """
    Collect necessary inputs from the user interactively.
    """
    input(
        "Step 1: Create a repository using the Azure SAP Automation Deployer template.\n"
        "Visit this link to create the repository: https://github.com/new?template_name=sap-automation-gh-bootstrap&template_owner=Azure\n"
        "Press Enter after creating the repository.\n"
    )

    token = getpass.getpass(
        "Step 2: Visit this link to create the PAT: https://github.com/settings/tokens/new?scopes=repo,admin:repo_hook,workflow\n"
        "Enter your GitHub Personal Access Token (PAT): "
    ).strip()
    repo_name = input(
        "Step 3: Enter the full repository name (e.g., 'owner/repository'): "
    ).strip()
    owner = repo_name.split("/")[0]
    server_url = (
        input(
            "Step 4: Enter the GitHub server URL (default: 'https://github.com'): "
        ).strip()
        or "https://github.com"
    )

    print("\nCreating the GitHub App...\n")
    print(f"Visit the following link to create your GitHub App:")
    print(
        f"You can use the following link to create the app requirements: "
        f"{server_url}/settings/apps/new?name={owner}-sap-on-azure&description=Used%20to%20create%20environments,%20update%20and%20create%20secrets%20and%20variables%20for%20your%20SAP%20on%20Azure%20Setup."
        f"&callback=false&request_oauth_on_install=false&public=true&actions=read&administration=write&contents=write"
        f"&environments=write&issues=write&secrets=write&actions_variables=write&workflows=write&webhook_active=false&url={server_url}/{repo_name}"
    )
    input(
        "\nPress Enter after creating the GitHub App and downloading the private key."
    )

    gh_app_name = input("Enter the GitHub App name: ").strip()
    gh_app_id = input("Enter the App ID (displayed in the GitHub App settings): ").strip()

    while True:
        print(f"Enter the path to the downloaded private key file")
        print(f"(you can download the private key from here: https://github.com/settings/apps/{gh_app_name}#private-key):")
        private_key_path = input().strip('"\'')
        normalized_path = os.path.normpath(private_key_path)
        # Read the private key
        try:
            with open(normalized_path, "r") as file:
                private_key = file.read()
            break
        except FileNotFoundError:
            print(f"Error: Could not find the private key file at: {private_key_path}")
            print("Make sure you've entered the correct file path.")
        except PermissionError:
            print(f"Error: Permission denied when trying to read: {private_key_path}")
            print("Make sure you have the necessary permissions to read this file.")
        except Exception as e:
            print(f"Error reading private key file: {str(e)}")
            print("Please check the file path and try again.")
            continue

    print("\n[OPTIONAL] If you're using a GitHub organization account (not a personal account):")
    print("You'll need to make this GitHub App public for it to work properly with organization repositories.")
    print("For personal GitHub accounts, you can skip this step.")
    is_org_account = input("Are you using a GitHub organization account? (y/n): ").strip().lower()

    if is_org_account in ['y', 'yes']:
        advanced_settings_url = f"https://github.com/settings/apps/{gh_app_name}/advanced"
        print(f"\nVisit the following URL to set the GitHub App to public: {advanced_settings_url}")
        print("In the Advanced tab, scroll down to 'Make this GitHub App public' and check the box.")
        input("Press Enter after setting the GitHub App to public.\n")
    else:
        print("\nSkipping the 'Make public' step since you're using a personal account.\n")

    # Provide the installation URL for the GitHub App
    installation_url = f"https://github.com/settings/apps/{gh_app_name}/installations"
    print(
        f"\nPlease visit the following URL and press install the GitHub App: {installation_url}"
    )
    input("Press Enter after installing the GitHub App.\n")

    while True:
        control_plane_name = input(
            "Enter the Control Plane name (e.g., 'MGMT-WEEU-DEP01')\n"
            "Format: <Environment>-<RegionCode>-<VNetName>\n"
            "  - Environment: max 5 characters (e.g., MGMT, PROD)\n"
            "  - Region Code: 4 characters (e.g., WEEU, NOEU, EUS2)\n"
            "  - VNet Name: max 7 characters (e.g., DEP01)\n"
            "Control Plane name: "
        ).strip().upper()

        # Validate format
        parts = control_plane_name.split('-')
        if len(parts) != 3:
            print("Error: Control Plane name must have format: <Environment>-<RegionCode>-<VNetName>")
            print("Example: MGMT-WEEU-DEP01")
            continue

        environment = parts[0]
        region_code = parts[1]
        vnet_name = parts[2]

        # Validate each component
        if len(environment) > 5:
            print(f"Error: Environment code '{environment}' must be maximum 5 characters.")
            continue
        if len(region_code) != 4:
            print(f"Error: Region code '{region_code}' must be exactly 4 characters.")
            continue
        if len(vnet_name) > 7:
            print(f"Error: VNet name '{vnet_name}' must be maximum 7 characters.")
            continue

        print(f"\nParsed Control Plane components:")
        print(f"  Environment: {environment}")
        print(f"  Region Code: {region_code}")
        print(f"  VNet Name: {vnet_name}")

        confirm = input("Is this correct? (y/n): ").strip().lower()
        if confirm in ['y', 'yes']:
            break

    # Azure details
    # Check if the user is logged in and get subscription and tenant details
    is_logged_in = verify_azure_login()

    subscription_id = ""
    tenant_id = ""

    if is_logged_in:
        # Get the current subscription ID automatically
        print("Fetching your current Azure subscription details...")
        sub_result = run_az_command([
            "account",
            "show",
            "--query",
            "id",
            "-o",
            "tsv"
        ], capture_output=True, text=True)

        if sub_result.returncode == 0 and sub_result.stdout.strip():
            subscription_id = sub_result.stdout.strip()
            print(f"Using subscription ID: {subscription_id}")

            # Get the tenant ID automatically
            tenant_result = run_az_command([
                "account",
                "show",
                "--query",
                "tenantId",
                "-o",
                "tsv"
            ], capture_output=True, text=True)

            if tenant_result.returncode == 0 and tenant_result.stdout.strip():
                tenant_id = tenant_result.stdout.strip()
                print(f"Using tenant ID: {tenant_id}")
            else:
                print("Could not automatically detect tenant ID.")
        else:
            print("Could not automatically detect subscription ID.")

    # Only prompt if we couldn't get the values automatically
    if not subscription_id:
        subscription_id = input("\nEnter your Azure Subscription ID: ").strip()

    if not tenant_id:
        tenant_id = input("Enter your Azure Tenant ID: ").strip()

    # Ask user to choose between Service Principal and Managed Identity
    print("\nChoose authentication method for GitHub Actions:")
    print("1. Service Principal (SPN) - traditional app registration with client secret")
    print("2. User Managed Identity (MSI) - more secure, no need for secrets")
    print("\nNote: Even if you choose User Managed Identity, GitHub Actions requires a Service Principal")
    print("for initial authentication until a self-hosted runner is set up.")

    auth_choice = ""
    while auth_choice not in ["1", "2"]:
        auth_choice = input("\nEnter your choice (1/2): ").strip()
        if auth_choice not in ["1", "2"]:
            print("Invalid choice. Please enter 1 or 2.")

    use_managed_identity = (auth_choice == "2")

    # Initialize Service Principal related variables
    use_existing_spn = False
    spn_name = ""
    spn_appid = None
    spn_password = None
    spn_object_id = None

    # Initialize User-Assigned Managed Identity related variables
    use_existing_identity = False
    identity_name = ""
    identity_client_id = None
    identity_principal_id = None
    identity_id = None
    region_map = ""

    # Handle User-Assigned Managed Identity details if that option was selected
    resource_group_name = ""
    if use_managed_identity:  # If Managed Identity was selected
        print("\n--- User-Assigned Managed Identity Configuration ---")
        use_existing_identity = input("\nDo you want to use an existing User-Assigned Managed Identity? (y/n): ").strip().lower() in ['y', 'yes']

        if use_existing_identity:
            # Get details for existing User-Assigned Managed Identity
            identity_name = input("Enter the name of your existing User-Assigned Managed Identity: ").strip()
            identity_client_id = input("Enter the Client ID of your Managed Identity: ").strip()

            # Get the resource group for the existing identity
            resource_group_name = input("Enter the Resource Group containing the Managed Identity: ").strip()

            # Get the object/principal ID for the existing identity
            print("Retrieving Principal ID for the Managed Identity...")
            identity_show_args = [
                "identity",
                "show",
                "--name", identity_name,
                "--resource-group", resource_group_name
            ]
            identity_show_result = run_az_command(identity_show_args, capture_output=True, text=True)

            if identity_show_result.returncode != 0:
                print("Failed to retrieve Managed Identity information.")
                print(identity_show_result.stderr)
                exit(1)

            try:
                identity_show_data = json.loads(identity_show_result.stdout)
                identity_principal_id = identity_show_data["principalId"]
                identity_id = identity_show_data["id"]
                print(f"Successfully retrieved Principal ID: {identity_principal_id}")
            except (json.JSONDecodeError, KeyError):
                print("Failed to get Principal ID from Managed Identity data.")
                print(identity_show_result.stdout)
                exit(1)
        else:
            # Ask for Azure region for creating the new Managed Identity
            region_map = input(
                f"\nEnter Azure region to deploy to (full name for region code '{region_code}').\n"
                "Please use the short name (e.g., 'northeurope', 'westeurope', 'eastus2'): "
            ).strip()

            # Ask for resource group name for creating a new Managed Identity
            print("\nYou need to specify a resource group for creating the Managed Identity.")
            default_resource_group = f"{environment}-INFRASTRUCTURE-RG"
            print(f"The default resource group name would be: {default_resource_group}")
            use_default_rg = input(f"Would you like to use this default name? (y/n): ").strip().lower()
            resource_group_name = default_resource_group
            if use_default_rg not in ['y', 'yes']:
                while True:
                    resource_group_name = input("Enter your desired resource group name: ").strip()
                    if resource_group_name:
                        break
                    print("Resource group name cannot be empty. Please enter a valid name.")

    # Now handle Service Principal configuration
    print("\n--- Service Principal Configuration ---")
    if not use_managed_identity:
        # Service Principal is the primary auth method
        use_existing_spn = input("\nDo you want to use an existing Service Principal? (y/n): ").strip().lower() in ['y', 'yes']
    else:
        # For Managed Identity, still need an SPN for initial authentication
        print("\nYou'll need a Service Principal for initial GitHub Actions authentication.")
        use_existing_spn = input("Do you want to use an existing Service Principal for initial authentication? (y/n): ").strip().lower() in ['y', 'yes']

    if use_existing_spn:
        spn_name = input("Enter the name of your existing Service Principal: ").strip()
        spn_appid = input("Enter the Application (client) ID of your Service Principal: ").strip()
        generate_new_secret = input("Do you want to generate a new client secret? (y/n): ").strip().lower() in ['y', 'yes']

        if generate_new_secret:
            print("Generating a new client secret...")
            # First try to reset credential at the app level
            app_secret_args = [
                "ad",
                "app",
                "credential",
                "reset",
                "--id",
                spn_appid,
                "--display-name", "rbac",
            ]
            secret_result = run_az_command(app_secret_args, capture_output=True, text=True)

            # If app credential reset fails, try service principal credential reset
            if secret_result.returncode != 0:
                print("App credential reset failed, trying service principal credential reset...")
                sp_secret_args = [
                    "ad",
                    "sp",
                    "credential",
                    "reset",
                    "--id",
                    spn_appid,
                    "--name", "rbac",
                ]
                secret_result = run_az_command(sp_secret_args, capture_output=True, text=True)

            if secret_result.returncode != 0:
                print("Failed to generate new client secret. Please check the error and try again.")
                print(secret_result.stderr)
                exit(1)

            try:
                secret_data = json.loads(secret_result.stdout)
                # Handle different JSON formats from different CLI versions/commands
                # Some return "password" directly, others may have it nested under "credentials"
                if "password" in secret_data:
                    spn_password = secret_data.get("password")
                elif "credential" in secret_data:
                    spn_password = secret_data.get("credential")
                elif "credentials" in secret_data and isinstance(secret_data["credentials"], list) and len(secret_data["credentials"]) > 0:
                    spn_password = secret_data["credentials"][0].get("password")
                else:
                    raise ValueError("Could not find password in the response")

                if not spn_password:
                    print("Failed to get the generated client secret.")
                    exit(1)
                print("Successfully generated a new client secret.")
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Failed to decode JSON for client secret: {str(e)}")
                print(secret_result.stdout)
                exit(1)
        else:
            spn_password = getpass.getpass("Enter the client secret for your Service Principal: ").strip()

            # Get the object ID for the existing service principal
            print("Retrieving Object ID for the Service Principal...")
            spn_show_args = [
                "ad",
                "sp",
                "show",
                "--id",
                spn_appid
            ]
            spn_show_result = run_az_command(spn_show_args, capture_output=True, text=True)

            if spn_show_result.returncode != 0:
                print("Failed to retrieve Service Principal information.")
                print(spn_show_result.stderr)
                exit(1)

            try:
                spn_show_data = json.loads(spn_show_result.stdout)
                spn_object_id = spn_show_data["id"]
                print(f"Successfully retrieved Object ID: {spn_object_id}")
            except (json.JSONDecodeError, KeyError):
                print("Failed to get Object ID from Service Principal data.")
                print(spn_show_result.stdout)
                print("\n\033[1;33mWARNING: Using a placeholder value for Object ID.\033[0m")
                print("This may cause issues during deployment. You should verify the Object ID manually.")
                spn_object_id = "PLACEHOLDER-OBJECT-ID"

    else:
        # Only ask for SPN name if creating a new one
        spn_name = input("Enter the name for the new Azure Service Principal: ").strip()
        # Flag to indicate we need to create a new SPN
        spn_appid = None
        spn_password = None
        spn_object_id = None

    # SAP S-User credentials
    add_suser = input("\nDo you want to add SAP S-User credentials? (y/n): ").strip().lower()
    s_username = ""
    s_password = ""
    if add_suser in ['y', 'yes']:
        s_username = input("Enter your SAP S-Username: ").strip()
        s_password = getpass.getpass("Enter your SAP S-User password: ").strip()

    # Docker image for SDAF
    default_docker_image = "ghcr.io/Azure/sap-automation:main"
    print(f"\nDocker image for SDAF (default: {default_docker_image})")
    custom_docker_image = input(f"Enter a custom Docker image or press Enter to use the default: ").strip()
    docker_image = custom_docker_image if custom_docker_image else default_docker_image

    return {
        "token": token,
        "repo_name": repo_name,
        "owner": owner,
        "server_url": server_url,
        "gh_app_name": gh_app_name,
        "gh_app_id": gh_app_id,
        "private_key": private_key,
        "control_plane_name": control_plane_name,
        "environment": environment,
        "region_code": region_code,
        "vnet_name": vnet_name,
        "region_map": region_map,
        "subscription_id": subscription_id,
        "tenant_id": tenant_id,
        "auth_choice": auth_choice,  # Add authentication choice
        # Service Principal related parameters
        "spn_name": spn_name,
        "use_existing_spn": use_existing_spn if 'use_existing_spn' in locals() else False,
        "spn_appid": spn_appid if 'spn_appid' in locals() else None,
        "spn_password": spn_password if 'spn_password' in locals() else None,
        "spn_object_id": spn_object_id if 'spn_object_id' in locals() else None,
        # Managed Identity related parameters
        "use_managed_identity": use_managed_identity,
        "use_existing_identity": use_existing_identity if 'use_existing_identity' in locals() else False,
        "identity_name": identity_name if 'identity_name' in locals() else None,
        "identity_client_id": identity_client_id if 'identity_client_id' in locals() else None,
        "identity_principal_id": identity_principal_id if 'identity_principal_id' in locals() else None,
        "identity_id": identity_id if 'identity_id' in locals() else None,
        # Other parameters
        "s_username": s_username,
        "s_password": s_password,
        "resource_group": resource_group_name,
        "docker_image": docker_image,
    }


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
        repo.create_variable(variable_name, variable_value)
        print(f"*** Variable {variable_name} added to repository {repo_full_name}.***")


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


# Azure login function removed as login is now expected to be done outside the script


def verify_azure_login():
    """
    Verify if the user is logged into Azure CLI.
    Returns True if logged in, False otherwise.
    """
    print("\nVerifying Azure CLI login status...\n")
    try:
        result = run_az_command(["account", "show", "--query", "name", "-o", "tsv"], capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            print(f"Currently logged in to Azure account: {result.stdout.strip()}")
            return True
        else:
            print("Not logged in to Azure CLI.")
            return False
    except Exception as e:
        print(f"Error verifying Azure login: {str(e)}")
        return False

def verify_subscription(subscription_id):
    """
    Verify if the subscription exists and set it as the current subscription.

    Args:
        subscription_id: The Azure subscription ID

    Returns:
        True if subscription set successfully, False otherwise.
    """
    try:
        result = run_az_command(["account", "set", "--subscription", subscription_id], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"Set subscription context to: {subscription_id}")
            return True
        else:
            print(f"Failed to set subscription context: {result.stderr}")
            return False
    except Exception as e:
        print(f"Error verifying subscription: {str(e)}")
        return False

def verify_resource_group(resource_group, subscription_id):
    """
    Verify if the resource group exists in the specified subscription.

    Args:
        resource_group: The resource group name
        subscription_id: The Azure subscription ID

    Returns:
        True if resource group exists, False otherwise.
    """
    try:
        # First check that the subscription exists and is accessible
        sub_check_args = ["account", "show", "--subscription", subscription_id, "--query", "name", "-o", "tsv"]
        sub_result = run_az_command(sub_check_args, capture_output=True, text=True)

        if sub_result.returncode != 0:
            print(f"Error: Cannot access subscription '{subscription_id}'")
            print(f"Details: {sub_result.stderr}")
            print("Please make sure the subscription ID is correct and you have access to it.")
            return False

        # Now check if the resource group exists
        rg_check_args = ["group", "exists", "--name", resource_group]
        rg_result = run_az_command(rg_check_args, capture_output=True, text=True)

        if rg_result.returncode == 0 and rg_result.stdout.strip().lower() == "true":
            print(f"✓ Resource group '{resource_group}' exists in subscription '{subscription_id}'")
            return True
        else:
            print(f"! Resource group '{resource_group}' does not exist in subscription '{subscription_id}'")
            print("The resource group will need to be created before proceeding.")
            return False

    except Exception as e:
        print(f"Error verifying resource group: {str(e)}")
        return False

def create_user_assigned_identity(identity_name, resource_group, subscription_id, location):
    """
    Create a user-assigned identity in Azure and assign required roles.

    Args:
        identity_name: Name of the user-assigned identity
        resource_group: Resource group where the identity will be created
        subscription_id: Azure subscription ID
        location: Azure region where the identity will be created

    Returns:
        Dictionary with identity details if successful, None otherwise.
    """
    print(f"\nCreating user-assigned identity '{identity_name}' in resource group '{resource_group}'...\n")

    # Define the roles to assign
    roles = [
        "Contributor",
        "User Access Administrator",
        "Storage Blob Data Owner",
        "Key Vault Administrator",
        "App Configuration Data Owner"
    ]

    # Verify Azure login
    if not verify_azure_login():
        print("Please login to Azure CLI first using 'az login' before running this script")
        return None

    # Verify and set subscription
    if not verify_subscription(subscription_id):
        return None

    # Verify resource group exists
    if not verify_resource_group(resource_group, subscription_id):
        return None

    # Create the user-assigned identity
    try:
        identity_result = run_az_command([
            "identity", "create",
            "--name", identity_name,
            "--resource-group", resource_group,
            "--location", location,
            "--query", "{id:id, principalId:principalId, clientId:clientId}",
            "-o", "json"
        ], capture_output=True, text=True)

        if identity_result.returncode != 0:
            print(f"Failed to create user-assigned identity: {identity_result.stderr}")
            return None

        identity = json.loads(identity_result.stdout)
        print(f"Successfully created user-assigned identity '{identity_name}'")
        print(f"Identity ID: {identity['id']}")
        print(f"Principal ID: {identity['principalId']}")
        print(f"Client ID: {identity['clientId']}")

        # Assign roles to the identity
        role_assignments = []
        roles_failed = []

        for role_name in roles:
            print(f"Assigning role {role_name} to the Managed Identity")
            role_result = run_az_command([
                "role", "assignment", "create",
                "--assignee-object-id", identity['principalId'],
                "--assignee-principal-type", "ServicePrincipal",
                "--role", role_name,
                "--scope", f"/subscriptions/{subscription_id}",
                "--query", "id",
                "--output", "tsv",
                "--only-show-errors"
            ], capture_output=True, text=True)

            if role_result.returncode == 0:
                print(f"✓ Successfully assigned {role_name} role to identity")
                role_assignments.append({
                    "role": role_name,
                    "id": role_result.stdout.strip()
                })
            else:
                print(f"✗ Failed to assign {role_name} role")
                roles_failed.append(role_name)

        # Show warning if role assignment failed
        if roles_failed:
            print("\n\033[1;33mWARNING: Not all roles could be assigned to the Managed Identity.\033[0m")
            print("Your user account may not have permission to assign the following roles:")
            for role in roles_failed:
                print(f"  - {role}")

            print("\nRecommended roles that should be assigned to this Managed Identity:")
            for role in roles:
                print(f"  - {role}")

            print(f"\nPlease have an Azure subscription administrator assign these roles")
            print(f"to the Managed Identity '{identity_name}' (Principal ID: {identity['principalId']}).")
            print("The script will continue, but deployment may fail without proper permissions.")

        # Return the identity details
        return {
            "name": identity_name,
            "resourceGroup": resource_group,
            "subscriptionId": subscription_id,
            "identityId": identity["id"],
            "principalId": identity["principalId"],
            "clientId": identity["clientId"],
            "roleAssignments": role_assignments
        }

    except Exception as e:
        print(f"An error occurred while creating the identity: {str(e)}")
        return None

def create_azure_service_principal(user_data):
    """
    Create or use an existing Azure service principal and assign roles.
    """
    # If using an existing Service Principal
    if user_data.get("use_existing_spn"):
        print(f"\nUsing existing Service Principal '{user_data['spn_name']}'...\n")

        # Create a data structure that matches the expected output
        # Ensure all required fields are present, use placeholders if missing
        app_id = user_data["spn_appid"]
        password = user_data["spn_password"]
        object_id = user_data["spn_object_id"]

        # Validate critical fields and set placeholders if missing
        if not app_id:
            print("\n\033[1;33mWARNING: Application ID is missing. Using placeholder value.\033[0m")
            app_id = "PLACEHOLDER-APP-ID"

        if not password:
            print("\n\033[1;33mWARNING: Client secret is missing. Using placeholder value.\033[0m")
            password = "PLACEHOLDER-CLIENT-SECRET"

        if not object_id:
            print("\n\033[1;33mWARNING: Object ID is missing. Using placeholder value.\033[0m")
            print("This may cause issues during deployment. You should verify the Object ID manually.")
            object_id = "PLACEHOLDER-OBJECT-ID"

        spn_data = {
            "appId": app_id,
            "password": password,
            "object_id": object_id
        }

        # Diagnose any potential issues with the Service Principal
        success, diagnosis = diagnose_service_principal_issues(user_data["spn_appid"], user_data["subscription_id"])
        print(diagnosis)

        # Continue with verifying and assigning required roles
        print("Verifying and assigning required roles to the Service Principal...")

        # Define the recommended roles for existing SPN
        recommended_roles = [
            "User Access Administrator",
            "Contributor",
            "Storage Blob Data Owner",
            "Key Vault Administrator",
            "App Configuration Data Owner"
        ]

        # First check User Access Administrator role assignment to avoid duplication errors
        check_role_args = [
            "role",
            "assignment",
            "list",
            "--assignee",
            user_data["spn_appid"],
            "--role",
            "User Access Administrator",
            "--scope",
            f"/subscriptions/{user_data['subscription_id']}",
        ]

        check_result = run_az_command(check_role_args, capture_output=True, text=True)
        if check_result.returncode != 0:
            print("Failed to check existing role assignments.")
            print(check_result.stderr)
            return None

        # If role is not already assigned, assign it
        try:
            roles = json.loads(check_result.stdout)
            role_exists = len(roles) > 0

            if not role_exists:
                print("Assigning User Access Administrator role...")
                role_args = [
                    "role",
                    "assignment",
                    "create",
                    "--assignee",
                    user_data["spn_appid"],
                    "--role",
                    "User Access Administrator",
                    "--scope",
                    f"/subscriptions/{user_data['subscription_id']}",
                ]

                role_result = run_az_command(role_args, capture_output=True, text=True)
                if role_result.returncode != 0:
                    print("\nWARNING: Failed to assign User Access Administrator role.")
                    print("Your user account does not have permission to assign roles.")
                    print("\nRecommended roles that should be assigned to this Service Principal:")
                    print("  - User Access Administrator")
                    print("  - Contributor")
                    print("  - Storage Blob Data Owner")
                    print("  - Key Vault Administrator")
                    print("  - App Configuration Data Owner")
                    print("\nPlease have an Azure subscription administrator assign these roles")
                    print("to the Service Principal before deploying SAP workload.")
                    print("The script will continue, but deployment may fail without proper permissions.")
                else:
                    print("User Access Administrator role assigned successfully.")
            else:
                print("User Access Administrator role is already assigned.")

        except json.JSONDecodeError:
            print("Failed to parse role assignment check output.")
            print(check_result.stdout)

        return spn_data

    # If creating a new Service Principal
    else:
        print(f"\nCreating new Azure Service Principal '{user_data['spn_name']}'...\n")
        spn_create_args = [
            "ad",
            "sp",
            "create-for-rbac",
            "--name",
            user_data["spn_name"],
            "--role",
            "contributor",
            "--scopes",
            f"/subscriptions/{user_data['subscription_id']}",
            "--only-show-errors",
        ]
        result = run_az_command(spn_create_args, capture_output=True, text=True)
        if result.returncode != 0:
            print(
                "Failed to create service principal. Please ensure you are logged in to Azure and try again."
            )
            print(result.stderr)
            return None

        try:
            spn_data = json.loads(result.stdout)
        except json.JSONDecodeError:
            print(
                "Failed to decode JSON from the output. Please check the Azure CLI command output."
            )
            print(result.stdout)
            return None

        # Get the service principal object ID
        spn_show_args = [
            "ad",
            "sp",
            "show",
            "--id",
            spn_data["appId"],
        ]
        spn_show_result = run_az_command(spn_show_args, capture_output=True, text=True)
        if spn_show_result.returncode != 0:
            print(
                "Failed to retrieve service principal object ID. Please check the Azure CLI command output."
            )
            print(spn_show_result.stderr)
            print("\n\033[1;33mWARNING: Using a placeholder value for Object ID.\033[0m")
            print("This may cause issues during deployment. You should verify the Object ID manually.")
            spn_data["object_id"] = "PLACEHOLDER-OBJECT-ID"
        else:
            try:
                spn_show_data = json.loads(spn_show_result.stdout)
                spn_data["object_id"] = spn_show_data["id"]
                print(f"Successfully retrieved Object ID: {spn_data['object_id']}")
            except json.JSONDecodeError:
                print(
                    "Failed to decode JSON from the output. Please check the Azure CLI command output."
                )
                print(spn_show_result.stdout)
                print("\n\033[1;33mWARNING: Using a placeholder value for Object ID.\033[0m")
                print("This may cause issues during deployment. You should verify the Object ID manually.")
                spn_data["object_id"] = "PLACEHOLDER-OBJECT-ID"

        # Assign required roles
        print("Assigning necessary roles to the Service Principal...")

        # Define the recommended roles
        recommended_roles = [
            "User Access Administrator",
            "Contributor",
            "Storage Blob Data Owner",
            "Key Vault Administrator",
            "App Configuration Data Owner"
        ]

        # Try to assign roles
        roles_assigned = False
        roles_failed = []

        for role_name in recommended_roles:
            print(f"Attempting to assign {role_name} role...")
            role_assignment_args = [
                "role",
                "assignment",
                "create",
                "--assignee",
                spn_data["appId"],
                "--role",
                role_name,
                "--scope",
                f"/subscriptions/{user_data['subscription_id']}",
                "--only-show-errors"
            ]

            try:
                role_result = run_az_command(role_assignment_args, capture_output=True, text=True)
                if role_result.returncode == 0:
                    print(f"✓ Successfully assigned {role_name} role.")
                    roles_assigned = True
                else:
                    print(f"✗ Failed to assign {role_name} role.")
                    roles_failed.append(role_name)
            except Exception as e:
                print(f"Error assigning {role_name} role: {str(e)}")
                roles_failed.append(role_name)

        # Show warning if role assignment failed
        if roles_failed:
            print("\n\033[1;33mWARNING: Not all roles could be assigned to the Service Principal.\033[0m")
            print("Your user account may not have permission to assign the following roles:")
            for role in roles_failed:
                print(f"  - {role}")

            print("\nPlease have an Azure subscription administrator assign these roles")
            print(f"to the Service Principal '{user_data['spn_name']}' (App ID: {spn_data['appId']}).")
            print("The script will continue, but deployment may fail without proper permissions.")

    return spn_data


def configure_federated_identity(user_data, spn_data):
    """
    Configure federated identity credential on the Microsoft Entra application.
    """
    print("\nConfiguring federated identity credential...\n")

    # Create parameters JSON for the federated credential
    parameters = {
        "name": "GitHubActions",
        "issuer": "https://token.actions.githubusercontent.com",
        "subject": f"repo:{user_data['repo_name']}:environment:{user_data['environment_name']}",
        "description": f"{user_data['environment_name']}-deploy",
        "audiences": ["api://AzureADTokenExchange"]
    }

    # Convert parameters to a JSON string
    parameters_json = json.dumps(parameters)

    # Create the federated credential
    federated_args = [
        "ad",
        "app",
        "federated-credential",
        "create",
        "--id",
        spn_data['appId'],
        "--parameters",
        parameters_json
    ]

    result = run_az_command(federated_args, capture_output=True, text=True)

    if result.returncode == 0:
        print("Federated identity credential configured successfully.")
    else:
        print("Warning: There was an issue configuring federated identity credential.")
        print(f"Error: {result.stderr}")
        print("You may need to set it up manually in the Azure portal.")


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


def diagnose_service_principal_issues(spn_appid, subscription_id):
    """
    Diagnoses common Service Principal permission and access issues.

    Args:
        spn_appid: The Service Principal application ID
        subscription_id: The Azure subscription ID

    Returns:
        A tuple of (bool, str) indicating success and diagnosis information
    """
    print("\nDiagnosing Service Principal permissions and access...\n")

    issues = []
    success = True

    # Check if the Service Principal exists
    print("Checking if Service Principal exists...")
    sp_show_args = ["ad", "sp", "show", "--id", spn_appid]
    sp_show_result = run_az_command(sp_show_args, capture_output=True, text=True)

    if sp_show_result.returncode != 0:
        issues.append("Service Principal does not exist or you don't have permission to access it.")
        success = False
    else:
        print("✓ Service Principal exists.")

        # Check subscription access
        print("Checking subscription access...")
        sub_role_args = [
            "role",
            "assignment",
            "list",
            "--assignee",
            spn_appid,
            "--scope",
            f"/subscriptions/{subscription_id}"
        ]
        sub_role_result = run_az_command(sub_role_args, capture_output=True, text=True)

        if sub_role_result.returncode != 0:
            issues.append("Error checking subscription role assignments.")
            success = False
        else:
            try:
                roles = json.loads(sub_role_result.stdout)
                if not roles:
                    issues.append(f"Service Principal has no role assignments on subscription {subscription_id}.")
                    success = False
                else:
                    role_names = [role.get("roleDefinitionName") for role in roles if "roleDefinitionName" in role]
                    print(f"✓ Service Principal has the following roles: {', '.join(role_names)}")

                    # Check if it has the required roles
                    required_roles = ["Contributor", "User Access Administrator"]
                    missing_roles = [role for role in required_roles if role not in role_names]

                    if missing_roles:
                        issues.append(f"Service Principal is missing the following recommended roles: {', '.join(missing_roles)}")
            except json.JSONDecodeError:
                issues.append("Unable to parse role assignments response.")
                success = False

    # Format the diagnosis result
    if success:
        diagnosis = "Service Principal permissions and access look good!\n"
    else:
        diagnosis = "The following issues were detected with the Service Principal:\n"
        for i, issue in enumerate(issues, 1):
            diagnosis += f"{i}. {issue}\n"

        diagnosis += "\nRecommendations:\n"
        diagnosis += "1. Ensure the Service Principal exists and is active.\n"
        diagnosis += "2. Make sure you have permissions to view and modify the Service Principal.\n"
        diagnosis += "3. The following roles should be assigned to the Service Principal:\n"
        diagnosis += "   - Contributor: For creating and managing resources\n"
        diagnosis += "   - User Access Administrator: For assigning roles to other identities\n"
        diagnosis += "   - Storage Blob Data Owner: For accessing blob storage data\n"
        diagnosis += "   - Key Vault Administrator: For managing secrets in Key Vault\n\n"
        diagnosis += "If you don't have permissions to assign these roles, please contact your Azure\n"
        diagnosis += "subscription administrator to assign them before deploying SAP workloads.\n"
        diagnosis += "The script will continue, but deployment may fail without proper permissions.\n"

    return success, diagnosis

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

def get_current_subscription_info():
    """
    Gets information about the currently active Azure subscription.

    Returns:
        A tuple (success, subscription_id, subscription_name) where:
        - success is a boolean indicating if information was retrieved successfully
        - subscription_id is the current subscription ID or None
        - subscription_name is the current subscription name or None
    """
    print("\nRetrieving current Azure subscription information...\n")

    # Check if logged in first
    if not verify_azure_login():
        print("You need to be logged in to Azure CLI.")
        print("Please run 'az login' in a terminal before proceeding.")
        return False, None, None

    # Get current subscription info
    show_result = run_az_command([
        "account",
        "show",
        "--query",
        "{name:name, id:id}",
        "--output",
        "json"
    ], capture_output=True, text=True)

    if show_result.returncode != 0:
        print(f"Error retrieving subscription information: {show_result.stderr}")
        return False, None, None

    try:
        subscription = json.loads(show_result.stdout)
        subscription_id = subscription.get("id")
        subscription_name = subscription.get("name")

        if subscription_id and subscription_name:
            print(f"Currently using subscription: {subscription_name} ({subscription_id})")
            return True, subscription_id, subscription_name
        else:
            print("Could not determine the current subscription.")
            return False, None, None

    except json.JSONDecodeError:
        print("Failed to parse subscription data.")
        print(show_result.stdout)
        return False, None, None

def main():
    """
    Main execution flow of the GitHub Repository/Environment/Secrets setup script.
    """
    display_instructions()
    check_prerequisites()

    # Add information about permissions
    print("\n\033[1mPermissions Information:\033[0m")
    print("The following roles are required for the deployment to work properly:")
    print("  - User Access Administrator: For assigning roles to resources")
    print("  - Contributor: For creating and managing Azure resources")
    print("  - Storage Blob Data Owner: For accessing blob storage data")
    print("  - Key Vault Administrator: For managing secrets in Key Vault")
    print("  - App Configuration Data Owner: For managing app configuration data")
    print("\nThe script will attempt to assign these roles, but if you don't have sufficient permissions,")
    print("you may need to ask an administrator to assign them later.")

    print("\nStarting setup process...\n")
    user_data = get_user_input()

    # Check if user selected Managed Identity or Service Principal
    use_managed_identity = user_data.get("auth_choice", "1") == "2"

    # Only set up resource group if using Managed Identity
    resource_group = ""
    if use_managed_identity:
        resource_group = user_data["resource_group"]
        print(f"\nChecking if resource group {resource_group} exists...")
        if not verify_resource_group(resource_group, user_data["subscription_id"]):
            print(f"Resource group {resource_group} doesn't exist. Creating it...")
            # Location from user's region_map
            create_rg_args = [
                "group",
                "create",
                "--name",
                resource_group,
                "--location",
                user_data["region_map"]
            ]
            print(f"Creating resource group in {user_data['region_map']}...")
            rg_result = run_az_command(create_rg_args, capture_output=True, text=True)

            if rg_result.returncode != 0:
                print(f"Failed to create resource group {resource_group}:")
                print(rg_result.stderr)
                print("\nPossible causes:")
                print("1. Insufficient permissions to create resource groups")
                print("2. The location may be invalid or unavailable")
                print("3. Another resource group with the same name exists in a different subscription")
                print("\nCannot continue without a valid resource group. Exiting.")
                exit(1)

            print(f"✓ Resource group {resource_group} successfully created in {user_data['region_map']}")

    print("\nCreating necessary credentials for GitHub Actions...\n")

    # Even if using Managed Identity, we need to create/use an SPN for initial GitHub Actions authentication
    # until a self-hosted runner with the MSI is available
    print("\nNote: GitHub Actions requires a Service Principal for initial authentication.")
    print("This SPN will be used for initial authentication until a self-hosted runner is set up.")

    # Create or use existing Service Principal for GitHub Actions authentication
    spn_for_github_auth = {}
    if "spn_name" in user_data and user_data["spn_name"]:
        # If user already provided SPN details when collecting inputs, use those
        print(f"\nUsing provided Service Principal '{user_data['spn_name']}' for GitHub Actions authentication...")
        spn_for_github_auth = create_azure_service_principal(user_data)
    else:
        # Otherwise, create a temporary SPN for initial authentication
        default_spn_name = f"{user_data['environment']}-SDAF-SPN"
        print(f"\nYou need to create a Service Principal for initial GitHub Actions authentication.")
        print(f"The default name would be: {default_spn_name}")
        use_default_name = input(f"Would you like to use this default name? (y/n): ").strip().lower()

        temp_spn_name = default_spn_name
        if use_default_name not in ['y', 'yes']:
            temp_spn_name = input("Enter a name for the Service Principal: ").strip()

        print(f"\nCreating Service Principal '{temp_spn_name}' for initial GitHub Actions authentication...")

        # Create a temporary user_data structure for SPN creation
        spn_user_data = user_data.copy()
        spn_user_data["spn_name"] = temp_spn_name
        spn_user_data["use_existing_spn"] = False

        spn_for_github_auth = create_azure_service_principal(spn_user_data)

    if not spn_for_github_auth:
        print("\nFailed to create/configure Service Principal for initial GitHub Actions authentication.")
        print("Cannot continue without creating the service principal. Exiting.")
        exit(1)

    # Now proceed with Managed Identity if selected
    if use_managed_identity:
        if user_data.get("use_existing_identity", False):
            # Use existing User-Assigned Managed Identity
            print(f"\nUsing existing User-Assigned Managed Identity '{user_data['identity_name']}'...\n")

            # Create a data structure that matches what would be returned by create_user_assigned_identity
            identity_data = {
                "name": user_data["identity_name"],
                "resourceGroup": user_data["resource_group"],
                "subscriptionId": user_data["subscription_id"],
                "identityId": user_data.get("identity_id"),
                "principalId": user_data["identity_principal_id"],
                "clientId": user_data["identity_client_id"],
                "roleAssignments": []  # No new role assignments were created
            }

            # Verify the identity exists and is accessible
            identity_show_args = [
                "identity",
                "show",
                "--name", user_data["identity_name"],
                "--resource-group", user_data["resource_group"]
            ]
            identity_show_result = run_az_command(identity_show_args, capture_output=True, text=True)

            if identity_show_result.returncode != 0:
                print("\nFailed to verify access to the User-Assigned Managed Identity.")
                print(identity_show_result.stderr)
                print("Please check the following:")
                print("1. The identity name is correct")
                print("2. The resource group name is correct")
                print("3. You have sufficient permissions to access the identity")
                print("4. The identity exists in the specified resource group")
                exit(1)

            # Additional validation to ensure the client ID matches
            try:
                identity_data_from_azure = json.loads(identity_show_result.stdout)
                if identity_data_from_azure.get("clientId") != user_data["identity_client_id"]:
                    print("\nWarning: The Client ID you provided does not match the Client ID of the identity in Azure.")
                    print(f"Provided Client ID: {user_data['identity_client_id']}")
                    print(f"Actual Client ID: {identity_data_from_azure.get('clientId')}")
                    if input("Do you want to continue with the Client ID from Azure? (y/n): ").strip().lower() in ['y', 'yes']:
                        # Update the client ID to match what's in Azure
                        user_data["identity_client_id"] = identity_data_from_azure.get("clientId")
                        identity_data["clientId"] = identity_data_from_azure.get("clientId")
                        print("Using the Client ID from Azure.")
                    else:
                        print("Cannot continue with mismatched Client IDs. Exiting.")
                        exit(1)
            except (json.JSONDecodeError, KeyError) as e:
                print(f"Warning: Could not validate Client ID: {str(e)}")

            print("✓ Verified access to User-Assigned Managed Identity")

            # Check if the identity has the necessary roles assigned
            print("\nChecking role assignments for the Managed Identity...")
            required_roles = [
                "Contributor",
                "User Access Administrator",
                "Storage Blob Data Owner",
                "Key Vault Administrator",
                "App Configuration Data Owner"
            ]

            # Track assigned and failed roles for summary
            assigned_roles = []
            failed_roles = []

            for role_name in required_roles:
                role_check_args = [
                    "role",
                    "assignment",
                    "list",
                    "--assignee", user_data["identity_principal_id"],
                    "--role", role_name,
                    "--scope", f"/subscriptions/{user_data['subscription_id']}"
                ]
                role_check_result = run_az_command(role_check_args, capture_output=True, text=True)

                if role_check_result.returncode == 0:
                    try:
                        assignments = json.loads(role_check_result.stdout)
                        if assignments:
                            print(f"✓ Role '{role_name}' is already assigned")
                            assigned_roles.append(role_name)
                            # Add this existing role to the identity_data
                            identity_data.setdefault("roleAssignments", []).append({
                                "role": role_name,
                                "id": "existing"  # Marker for existing role
                            })
                        else:
                            # Role is not assigned, assign it
                            print(f"Role '{role_name}' is not assigned. Assigning it now...")
                            assign_role_args = [
                                "role",
                                "assignment",
                                "create",
                                "--assignee-object-id", user_data["identity_principal_id"],
                                "--assignee-principal-type", "ServicePrincipal",
                                "--role", role_name,
                                "--scope", f"/subscriptions/{user_data['subscription_id']}",
                                "--query", "id",
                                "--output", "tsv",
                                "--only-show-errors"
                            ]
                            assign_result = run_az_command(assign_role_args, capture_output=True, text=True)
                            if assign_result.returncode == 0:
                                assigned_roles.append(role_name)
                                role_id = assign_result.stdout.strip()
                                print(f"✓ Successfully assigned '{role_name}' role")
                                # Add this new role to the identity_data
                                identity_data.setdefault("roleAssignments", []).append({
                                    "role": role_name,
                                    "id": role_id
                                })
                            else:
                                print(f"Warning: Failed to assign '{role_name}' role: {assign_result.stderr}")
                                failed_roles.append(role_name)
                    except json.JSONDecodeError:
                        print(f"Warning: Could not verify if '{role_name}' role is assigned")
                        failed_roles.append(role_name)
                else:
                    print(f"Warning: Could not check role assignment for '{role_name}': {role_check_result.stderr}")
                    failed_roles.append(role_name)

            # Print summary of role assignments
            if assigned_roles:
                print("\nSummary of assigned roles:")
                for role in assigned_roles:
                    print(f"✓ {role}")
            if failed_roles:
                print("\nWarning: The following roles could not be assigned or verified:")
                for role in failed_roles:
                    print(f"✗ {role}")
                print("\nYou may need to manually assign these roles after the script completes.")
        else:
            # Create a new User-Assigned Managed Identity
            identity_name = f"{user_data['environment']}-github-identity"
            print(f"Creating User-Assigned Managed Identity: {identity_name}")

            identity_data = create_user_assigned_identity(
                identity_name=identity_name,
                resource_group=resource_group,
                subscription_id=user_data["subscription_id"],
                location=user_data["region_map"]
            )

            if not identity_data:
                print("\nFailed to create/configure User-Assigned Managed Identity.")
                print("Cannot continue without creating the managed identity. Exiting.")
                exit(1)

            # Update user_data with the newly created identity information for later use
            user_data["identity_id"] = identity_data["identityId"]
            user_data["identity_name"] = identity_data["name"]
            user_data["identity_client_id"] = identity_data["clientId"]
            user_data["identity_principal_id"] = identity_data["principalId"]
    else:
        # Create or use existing Service Principal based on user input
        spn_data = create_azure_service_principal(user_data)
        if not spn_data:
            print("\nFailed to create/configure Service Principal.")
            print("Cannot continue without creating the service principal. Exiting.")
            exit(1)

    print("\nGenerating GitHub secrets...\n")

    # Enter GitHub token to add repository secrets
    github_client = Github(user_data["token"])

    # Get the repo client
    repo = github_client.get_repo(user_data["repo_name"])

    # Generate secrets for the repository
    repository_secrets = generate_repository_secrets(user_data, user_data["gh_app_id"], user_data["private_key"])
    add_repository_secrets(github_client, user_data["repo_name"], repository_secrets)

    # Add repository-level variables
    # The Docker image can be customized by the user during setup
    repository_variables = {
        "DOCKER_IMAGE": user_data["docker_image"],
        "TF_IN_AUTOMATION": "true",
        "TF_LOG": "ERROR",
        "ANSIBLE_CORE_VERSION": "2.16",
        "TF_VERSION": "1.11.3"
    }
    print("\nAdding variables to repository level...")
    add_repository_variables(github_client, user_data["repo_name"], repository_variables)

    # Prepare environment variables
    environment_variables = {
        "ARM_SUBSCRIPTION_ID": user_data["subscription_id"],
        "ARM_TENANT_ID": user_data["tenant_id"],
        "USE_MSI": "true" if use_managed_identity else "false",
        # Add S_USERNAME with a placeholder if not provided
        "S_USERNAME": user_data["s_username"] if user_data["s_username"] else "Add SAP S Username here"
    }

    # Prepare environment secrets
    environment_secrets = {}

    if use_managed_identity:
        # For Managed Identity, set up both SPN (for initial auth) and MSI details
        # Set up environment variables for User-Assigned Managed Identity as primary auth method
        environment_variables.update({
            "ARM_CLIENT_ID": identity_data["clientId"],
            "ARM_OBJECT_ID": identity_data["principalId"],
        })

        # But also add SPN details for initial authentication
        environment_variables.update({
            "ARM_SPN_CLIENT_ID": spn_for_github_auth["appId"],
            "ARM_SPN_OBJECT_ID": spn_for_github_auth["object_id"],
        })

        # Add client secret to secrets
        environment_secrets["ARM_SPN_CLIENT_SECRET"] = spn_for_github_auth["password"]

        print("Environment configuration prepared for User Managed Identity with SPN for initial authentication")
    else:
        # Set up environment variables and secrets for Service Principal only
        environment_variables.update({
            "ARM_CLIENT_ID": spn_data["appId"],
            "ARM_OBJECT_ID": spn_data["object_id"],
        })
        # Add client secret to secrets
        environment_secrets["ARM_CLIENT_SECRET"] = spn_data["password"]
        print("Environment configuration prepared for Service Principal (USE_MSI=false)")

    # Add SAP S-User password and PAT to Environment secrets, with a placeholder if not provided
    environment_secrets["S_PASSWORD"] = user_data["s_password"] if user_data["s_password"] else "Add SAP S Password here"
    environment_secrets["PAT"] = user_data["token"]

    print(
        f"\nInitial setup completed successfully!\n"
        f"Repository: {user_data['repo_name']}\n"
    )

    print("\nConfiguration status:")
    if use_managed_identity:
        if user_data.get("use_existing_identity", False):
            print(f"- Using existing User-Assigned Managed Identity: {user_data['identity_name']}")
        else:
            print(f"- User-Assigned Managed Identity has been created: {identity_name}")

        # Also show SPN info (since it's needed for initial GitHub Actions authentication)
        # Use the actual SPN name from spn_for_github_auth or user data
        if user_data.get("use_existing_spn"):
            spn_name = user_data.get("spn_name")
            print(f"- Using existing Service Principal for initial GitHub Actions authentication: {spn_name}")
        else:
            # Get the actual name used when creating the SPN for initial auth (could be custom or default)
            spn_name = spn_user_data.get("spn_name") if 'spn_user_data' in locals() else user_data.get("spn_name")
            print(f"- Service Principal for initial GitHub Actions authentication has been created: {spn_name}")
            print("  (This SPN will be used until a self-hosted runner is set up)")
    else:
        if user_data.get("use_existing_spn", False):
            print(f"- Using existing Service Principal: {user_data['spn_name']}")
        else:
            print(f"- Service Principal has been created: {user_data['spn_name']}")

    if use_managed_identity:
        print(f"   - Managed Identity Name: {identity_data['name']}")
        print(f"   - Managed Identity Principal ID: {identity_data['principalId']}")
        print(f"   - Service Principal App ID: {spn_for_github_auth['appId']}")
        print(f"   - Service Principal Object ID: {spn_for_github_auth['object_id']}")
    else:
        print(f"   - Service Principal App ID: {spn_data['appId']}")
        print(f"   - Service Principal Object ID: {spn_data['object_id']}")

    print(f"   - Subscription ID: {user_data['subscription_id']}")
    print("3. The script has continued, but deployment may fail if permissions are not")
    print("   properly assigned before running workflows.")

    # Trigger the environment creation workflow
    workflow_id = "00-create-environment.yml"
    print(f"\nTriggering workflow '{workflow_id}' to create the environment...")

    if not trigger_github_workflow(user_data, workflow_id):
        print("CRITICAL ERROR: Failed to trigger environment creation workflow.")
        print("Cannot continue without successfully triggering the workflow.")
        exit(1)

    print("Environment creation workflow has been triggered successfully.")

    # Prompt for environment name after triggering the workflow
    print("\nWait for the workflow to complete, then:")
    environment_name = input(
        f"Visit this link https://github.com/{user_data['repo_name']}/settings/environments\n"
        "Enter the environment name that was created: "
    ).strip()

    # Update the environment name for federated identity and secrets
    user_data["environment_name"] = environment_name

    # Add variables to the newly created environment
    print(f"\nAdding variables to environment '{environment_name}'...")
    add_environment_variables(
        github_client, user_data["repo_name"], environment_name, environment_variables
    )

    # Add secrets to the newly created environment
    if environment_secrets:
        print(f"\nAdding secrets to environment '{environment_name}'...")
        add_environment_secrets(
            github_client, user_data["repo_name"], environment_name, environment_secrets
        )

    # Configure federated identity for the Service Principal (after getting the environment name)
    # When using MSI, we still need to configure federated identity for the initial auth SPN
    if use_managed_identity:
        # If using MSI, configure federated identity for the SPN used for initial authentication
        configure_federated_identity(user_data, spn_for_github_auth)
    else:
        # If using SPN as the primary method, configure federated identity for it
        configure_federated_identity(user_data, spn_data)

    print(f"\nSetup completed successfully!")
    print(f"Environment '{environment_name}' has been configured with all necessary variables and secrets.")
    print("You can now proceed with deploying your SAP environment using GitHub Actions.")

if __name__ == "__main__":
    main()

