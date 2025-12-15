import json
import getpass
from .utils import run_az_command

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
