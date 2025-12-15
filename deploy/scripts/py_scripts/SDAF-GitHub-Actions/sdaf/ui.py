import getpass
import os
import json
import sys
import platform
import shutil
import subprocess
from .utils import run_az_command
from .azure_ops import verify_azure_login

def display_instructions():
    print("""
        This script helps you automate the setup of a GitHub App, repository secrets,
        and environment for deploying SAP Deployment Automation Framework on Azure.

        Please follow these steps before running the script:
        1. Keep your repository name and owner ready.
        2. Be prepared to generate and download a private key for the GitHub App.
        """)

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
        "\nPress Enter after creating the GitHub App."
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
                sys.exit(1)
                
            try:
                identity_show_data = json.loads(identity_show_result.stdout)
                identity_principal_id = identity_show_data["principalId"]
                identity_id = identity_show_data["id"]
                print(f"Successfully retrieved Principal ID: {identity_principal_id}")
            except (json.JSONDecodeError, KeyError):
                print("Failed to get Principal ID from Managed Identity data.")
                print(identity_show_result.stdout)
                sys.exit(1)
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
                sys.exit(1)
                
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
                    sys.exit(1)
                print("Successfully generated a new client secret.")
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Failed to decode JSON for client secret: {str(e)}")
                print(secret_result.stdout)
                sys.exit(1)
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
                sys.exit(1)
                
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
