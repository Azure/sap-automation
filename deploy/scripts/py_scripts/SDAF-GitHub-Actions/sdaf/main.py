import sys
import json
from github import Github, GithubException
from . import ui
from . import azure_ops
from . import github_ops
from .utils import run_az_command

def main():
    """
    Main execution flow of the GitHub Repository/Environment/Secrets setup script.
    """
    ui.display_instructions()
    ui.check_prerequisites()

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
    user_data = ui.get_user_input()

    # Check if user selected Managed Identity or Service Principal
    use_managed_identity = user_data.get("auth_choice", "1") == "2"

    # Only set up resource group if using Managed Identity
    resource_group = ""
    if use_managed_identity:
        resource_group = user_data["resource_group"]
        print(f"\nChecking if resource group {resource_group} exists...")
        if not azure_ops.verify_resource_group(resource_group, user_data["subscription_id"]):
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
                sys.exit(1)

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
        spn_for_github_auth = azure_ops.create_azure_service_principal(user_data)
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

        spn_for_github_auth = azure_ops.create_azure_service_principal(spn_user_data)

    if not spn_for_github_auth:
        print("\nFailed to create/configure Service Principal for initial GitHub Actions authentication.")
        print("Cannot continue without creating the service principal. Exiting.")
        sys.exit(1)

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
                sys.exit(1)

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
                        sys.exit(1)
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

            identity_data = azure_ops.create_user_assigned_identity(
                identity_name=identity_name,
                resource_group=resource_group,
                subscription_id=user_data["subscription_id"],
                location=user_data["region_map"]
            )

            if not identity_data:
                print("\nFailed to create/configure User-Assigned Managed Identity.")
                print("Cannot continue without creating the managed identity. Exiting.")
                sys.exit(1)

            # Update user_data with the newly created identity information for later use
            user_data["identity_id"] = identity_data["identityId"]
            user_data["identity_name"] = identity_data["name"]
            user_data["identity_client_id"] = identity_data["clientId"]
            user_data["identity_principal_id"] = identity_data["principalId"]
    else:
        # Create or use existing Service Principal based on user input
        spn_data = azure_ops.create_azure_service_principal(user_data)
        if not spn_data:
            print("\nFailed to create/configure Service Principal.")
            print("Cannot continue without creating the service principal. Exiting.")
            sys.exit(1)

    print("\nGenerating GitHub secrets...\n")

    # Enter GitHub token to add repository secrets
    github_client = Github(user_data["token"])

    try:
        # Generate secrets for the repository
        repository_secrets = github_ops.generate_repository_secrets(user_data, user_data["gh_app_id"], user_data["private_key"])
        github_ops.add_repository_secrets(github_client, user_data["repo_name"], repository_secrets)

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
        github_ops.add_repository_variables(github_client, user_data["repo_name"], repository_variables)
    except GithubException as e:
        if e.status == 401:
            print("\nError: GitHub authentication failed. Please check your Personal Access Token (PAT).")
            print("Ensure the token is valid and has the necessary permissions (repo, workflow, admin:org).")
        elif e.status == 404:
            print(f"\nError: Repository '{user_data['repo_name']}' not found.")
            print("Please check the repository name and ensure your PAT has access to it.")
        else:
            print(f"\nGitHub Error: {e.data.get('message', str(e))}")
        sys.exit(1)

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

    if not github_ops.trigger_github_workflow(user_data, workflow_id):
        print("CRITICAL ERROR: Failed to trigger environment creation workflow.")
        print("Cannot continue without successfully triggering the workflow.")
        sys.exit(1)

    print("Environment creation workflow has been triggered successfully.")

    # Set the environment name to control_plane_name
    environment_name = user_data["control_plane_name"]
    user_data["environment_name"] = environment_name

    # Add variables to the newly created environment
    print(f"\nAdding variables to environment '{environment_name}'...")
    try:
        github_ops.add_environment_variables(
            github_client, user_data["repo_name"], environment_name, environment_variables
        )

        # Add secrets to the newly created environment
        if environment_secrets:
            print(f"\nAdding secrets to environment '{environment_name}'...")
            github_ops.add_environment_secrets(
                github_client, user_data["repo_name"], environment_name, environment_secrets
            )
    except GithubException as e:
        print(f"\nError updating environment '{environment_name}': {e.data.get('message', str(e))}")
        if e.status == 404:
            print("Ensure the environment exists and your PAT has access to it.")
        sys.exit(1)

    # Configure federated identity for the Service Principal (after getting the environment name)
    # When using MSI, we still need to configure federated identity for the initial auth SPN
    if use_managed_identity:
        # If using MSI, configure federated identity for the SPN used for initial authentication
        azure_ops.configure_federated_identity(user_data, spn_for_github_auth)
    else:
        # If using SPN as the primary method, configure federated identity for it
        azure_ops.configure_federated_identity(user_data, spn_data)

    print(f"\nSetup completed successfully!")
    print(f"Environment '{environment_name}' has been configured with all necessary variables and secrets.")
    print("You can now proceed with deploying your SAP environment using GitHub Actions.")
    print(f"Repository: {user_data['server_url']}/{user_data['repo_name']}")

if __name__ == "__main__":
    main()
