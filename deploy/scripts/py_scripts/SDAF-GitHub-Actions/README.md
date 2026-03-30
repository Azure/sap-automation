# SAP Deployment Automation Framework - GitHub Actions Setup

This script helps to automate the setup of a GitHub App, repository secrets, environment, and connection to Azure for deploying SAP Deployment Automation Framework on Azure.

## Features

1. **GitHub App Setup**: Creates and configures a GitHub App with the required permissions.
2. **Azure Integration**:  
   - Support for both Service Principal and User-Assigned Managed Identity authentication.
   - Interactive Azure subscription selection/changing at any point during execution.
   - Cross-platform support for Azure CLI operations.
3. **Secret Management**: Creates and stores all necessary secrets in GitHub repository and environment.
4. **Federated Identity**: Configures federated identity credentials for passwordless authentication.
5. **Error Diagnostics**: Provides diagnostics and troubleshooting for common issues.

### Prerequisites

1. **Python**: Ensure Python 3.10 or higher is installed on your machine. You can download it from [Python official website](https://www.python.org/downloads/). Note: on macOS, the preinstalled Python (if any) is often older than 3.10 (or may be missing); check `python3 --version` and install a newer version if needed (e.g. via [Homebrew](https://brew.sh): `brew install python@3.12`).
2. **Azure CLI**: Ensure the Azure CLI is installed. You can download it from [Azure CLI installation guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).
3. **Azure Login**: Run `az login` in your terminal to authenticate with Azure before running the script.

### Installation

1. **Clone the Repository**: clone the repository

    `git clone https://github.com/Azure/sap-automation.git`

2. Change directory
    `cd deploy/scripts/py_scripts/SDAF-GitHub-Actions`

3. **Create a Virtual Environment**: Create and activate a virtual environment using Python 3.10+. On macOS, if `python3` still points to the system/default Python (< 3.10), use the versioned binary (e.g. `python3.12`) instead.

    `python3 -m venv venv`

    > **macOS note**: If `python3 --version` reports < 3.10, run `python3.12 -m venv venv` (or whichever 3.10+ version you installed via Homebrew).

    On Unix/Linux/macOS (bash/zsh):

    `source venv/bin/activate`

    On Windows (Command Prompt):

    `venv\Scripts\activate.bat`

    On Windows (PowerShell):

    `venv\Scripts\Activate.ps1`

4. **Install Dependencies**: Install the required Python libraries.

    `pip install -r requirements.txt`

5. Running the Script

    `python New-SDAFGitHubActions.py`

### Authentication Options

The script supports two types of authentication for GitHub Actions:

1. **Service Principal (SPN)**: Traditional app registration with client secret.
   - You can create a new one or use an existing one.
   - The script will handle role assignments and federated identity configuration.

2. **User-Assigned Managed Identity (UAMI)**: More secure option that doesn't require secrets.
   - The script will create the identity and assign necessary roles.
   - This option provides better security as there are no secrets to manage.
