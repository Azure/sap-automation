#!/bin/bash

#
# configure_deployer.sh
#
# This script is intended to perform all the necessary initial
# setup of a node so that it can act as a deployer for use with
# Azure SAP Automated Deployment.
#
# As part of doing so it will:
#
#   * Installs the specifed version of terraform so that it
#     is available for all users.
#
#   * Installs the Azure CLI using the provided installer
#     script, making it available for all users.
#
#   * Create a Python virtualenv, which can be used by all
#     users, with the specified Ansible version and related
#     tools, and associated Python dependencies, installed.
#
#   * Create a /etc/profile.d file that will setup a users
#     interactive session appropriately to use these tools.
#
# This script does not modify the system's Python environment,
# instead using a Python virtualenv to host the installed Python
# packages, meaning that standard system updates can be safely
# installed.
#
# The script can be run again to re-install/update the required
# tools if needed. Note that doing so will re-generate the
# /etc/profile.d file, so any local changes will be lost.
#

#
# Setup some useful shell options
#

# Check if the script is running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root or with sudo. Please run as a regular user."
    exit 1
fi


# Print expanded commands as they are about to be executed
set -o xtrace

# Print shell input lines as they are read in
set -o verbose

# Fail if any command exits with a non-zero exit status
set -o errexit

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail


export local_user=$USER

#
# Terraform Version settings
#

if [ -z "${TF_VERSION}" ]; then
  TF_VERSION="1.7.0"
fi


# Fail if attempting to access and unset variable or parameter
set -o nounset

tfversion=$TF_VERSION

#
# Ansible Version settings
#
ansible_version="${ansible_version:-2.13}"
ansible_major="${ansible_version%%.*}"
ansible_minor=$(echo "${ansible_version}." | cut -d . -f 2)



#
# Utility Functions
#
distro_name=""
distro_version=""
distro_name_version=""
error()
{
    echo 1>&2 "ERROR: ${@}"
}

get_distro_name()
{
    typeset -g distro_name

    if [[ -z "${distro_name:-}" ]]; then
        distro_name="$(. /etc/os-release; echo "${ID,,}")"
    fi

    echo "${distro_name}"
}

get_distro_version()
{
    typeset -g distro_version

    if [[ -z "${distro_version:-}" ]]; then
        distro_version="$(. /etc/os-release; echo "${VERSION_ID,,}")"
    fi

    echo "${distro_version}"
}

get_distro_name_version()
{
    typeset -g distro_name_version

    if [[ -z "${distro_name_version:-}" ]]; then
        distro_name_version="$(get_distro_name)_$(get_distro_version)"
    fi

    echo "${distro_name_version}"
}

#
# Package Management Functions
#
pkg_mgr_init()
{
    typeset -g pkg_mgr

    case "$(get_distro_name)" in
    (ubuntu|debian)
        pkg_mgr="apt-get"
        pkg_type="deb"
        ;;
    (sles|opensuse*)
        pkg_mgr="zypper"
        pkg_type="rpm"
        ;;
    (rhel|centos|fedora)
        pkg_mgr="yum"
        pkg_type="rpm"
        ;;
    (*)
        error "Unsupported distibution: '${distro_name}'"
        exit 1
        ;;
    esac
}

pkg_mgr_refresh()
{
    typeset -g pkg_mgr pkg_mgr_refreshed

    if [[ -z ${pkg_mgr:-} ]]; then
        pkg_mgr_init
    fi

    if [[ -n ${pkg_mgr_refreshed:-} ]]; then
        return
    fi

    case ${pkg_mgr} in
    (apt-get)
        sudo "${pkg_mgr}" update --quiet
        ;;
    (zypper)
        set +o errexit
        sudo "${pkg_mgr}" --gpg-auto-import-keys --quiet refresh
        set -o errexit
        ;;
    (yum)
        sudo "${pkg_mgr}" update --quiet
        ;;
    esac

    pkg_mgr_refreshed=true
}


pkg_mgr_upgrade()
{
    typeset -g pkg_mgr pkg_mgr_upgraded

    if [[ -z ${pkg_mgr:-} ]]; then
        pkg_mgr_init
    fi

    if [[ -n ${pkg_mgr_upgraded:-} ]]; then
        return
    fi

    case ${pkg_mgr} in
    (apt-get)
        sudo "${pkg_mgr}" upgrade --quiet -y
        ;;
    (zypper)
        set +o errexit
        sudo "${pkg_mgr}" --gpg-auto-import-keys --non-interactive patch
        set -o errexit
        ;;
    (yum)
        sudo "${pkg_mgr}" upgrade --quiet -y
        ;;
    esac

    pkg_mgr_upgraded=true
}

pkg_mgr_install()
{
    typeset -g pkg_mgr

    pkg_mgr_refresh

    case ${pkg_mgr} in
    (apt-get)
        sudo env DEBIAN_FRONTEND=noninteractive ${pkg_mgr} --quiet --yes install "${@}"
        ;;
    (zypper)
      set +o errexit
      sudo "${pkg_mgr}" patch --auto-agree-with-licenses --with-interactive --no-confirm
      sleep 60
      sudo "${pkg_mgr}" --gpg-auto-import-keys --quiet --non-interactive install --no-confirm "${@}"
      set -o errexit
        ;;
    (yum)
        sudo "${pkg_mgr}" --nogpgcheck --quiet  install --assumeyes "${@}"
        ;;
    esac
}


#
# Directories and paths
#

# Ansible installation directories
ansible_base=/opt/ansible
ansible_bin="${ansible_base}/bin"
ansible_venv="${ansible_base}/venv/${ansible_version}"
ansible_venv_bin="${ansible_venv}/bin"
ansible_collections="${ansible_base}/collections"
ansible_pip3="${ansible_venv_bin}/pip3"

# Azure SAP Automated Deployment directories
asad_home="${HOME}/Azure_SAP_Automated_Deployment"
asad_ws="${asad_home}/WORKSPACES"
asad_repo="https://github.com/Azure/sap-automation.git"
asad_sample_repo="https://github.com/Azure/sap-automation-samples.git"
asad_dir="${asad_home}/$(basename ${asad_repo} .git)"
asad_sample_dir="${asad_home}/samples"

# Terraform installation directories
tf_base=/opt/terraform
tf_dir="${tf_base}/terraform_${tfversion}"
tf_bin="${tf_base}/bin"
tf_zip="terraform_${tfversion}_linux_amd64.zip"

#
#Don't re-run the following if the script is already installed
#

#
# Main body of script
#

# Check for supported distro
case "$(get_distro_name_version)" in
(sles_12*)
    error "Unsupported distro: ${distro_name_version} doesn't provide virtualenv in standard repos."
    exit 1
    ;;
(ubuntu*|sles*)
    echo "${distro_name_version} is supported."
    ;;
(rhel*)
    echo "${distro_name_version} is supported."
    ;;
(*)
    error "Unsupported distro: ${distro_name_version} not currently supported."
    exit 1
    ;;
esac

if [ "$(get_distro_version)" == "15.4" ]; then
    error "Unsupported distro: ${distro_name_version} at this time."
    exit 1
fi
if [ "$(get_distro_version)" == "15.5" ]; then
    error "Unsupported distro: ${distro_name_version} at this time."
    exit 1
fi


case "$(get_distro_name_version)" in
(sles*)
      set +o errexit
      zypper addrepo https://download.opensuse.org/repositories/network/SLE_15/network.repo
      set -o errexit
    ;;
esac

echo "Set ansible version for specific distros"
echo ""
case "$(get_distro_name)" in
(ubuntu)
  echo "we are inside ubuntu"
  rel=$(lsb_release -a | grep Release | cut -d':' -f2 | xargs)
  if [ "$rel" == "22.04" ]; then
    ansible_version="2.15"
    ansible_major="${ansible_version%%.*}"
    ansible_minor=$(echo "${ansible_version}." | cut -d . -f 2)
  fi
  ;;
(sles)
  echo "we are inside sles"
  ansible_version="2.11"
  ansible_major="${ansible_version%%.*}"
  ansible_minor=$(echo "${ansible_version}." | cut -d . -f 2)
  # Ansible installation directories
  ansible_base="/opt/ansible"
  ansible_bin="${ansible_base}/bin"
  ansible_venv="${ansible_base}/venv/${ansible_version}"
  ansible_venv_bin="${ansible_venv}/bin"
  ansible_collections="${ansible_base}/collections"
  ansible_pip3="${ansible_venv_bin}/pip3"
  sudo python3 -m pip install virtualenv;
  ;;
(rhel)
  echo "we are inside RHEL"
  ansible_version="2.11"
  ansible_major="${ansible_version%%.*}"
  ansible_minor=$(echo "${ansible_version}." | cut -d . -f 2)
  # Ansible installation directories
  ansible_base="/opt/ansible"
  ansible_bin="${ansible_base}/bin"
  ansible_venv="${ansible_base}/venv/${ansible_version}"
  ansible_venv_bin="${ansible_venv}/bin"
  ansible_collections="${ansible_base}/collections"
  ansible_pip3="${ansible_venv_bin}/pip3"
  sudo python3 -m pip install virtualenv;
  ;;
(*)
  echo "we are in the default case statement"
  ;;
esac

echo "Ansible version: ${ansible_version}"
# List of required packages whose names are common to all supported distros
required_pkgs=(
    git
    jq
    unzip
    ca-certificates
    curl
    gnupg
    dos2unix
)

cli_pkgs=(
)


# Include distro version agnostic packages into required packages list
case "$(get_distro_name)" in
(ubuntu)
    cli_pkgs+=(
        azure-cli
    )
    required_pkgs+=(
        sshpass
        python3-pip
        python3-virtualenv
        apt-transport-https
        lsb-release
        software-properties-common
    )
    ;;
(sles)
    required_pkgs+=(
        curl
        python3-pip
        lsb-release
    )
    ;;
(rhel)
    cli_pkgs+=(
        azure-cli
    )
    required_pkgs+=(
        sshpass
        python36
        python3-pip
        python3-virtualenv
    )
    ;;
esac
# Include distro version specific packages into required packages list
case "$(get_distro_name_version)" in
(ubuntu_18.04)
    required_pkgs+=(
        virtualenv
    )
    ;;
esac

echo "$(get_distro_name_version)"

# Upgrade packages
pkg_mgr_upgrade


# Ensure our package metadata cache is up to date
pkg_mgr_refresh

# Install required packages as determined above
pkg_mgr_install "${required_pkgs[@]}"

# # Install required packages as determined above
# pkg_mgr_install "${distro_required_pkgs[@]}"

rg_name=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" -s | jq .compute.resourceGroupName)

subscription_id=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" -s | jq .compute.subscriptionId)

# Prepare Azure SAP Automated Deployment folder structure
mkdir -p \
    "${asad_ws}"/LOCAL/"${rg_name}" \
    "${asad_ws}"/LIBRARY \
    "${asad_ws}"/SYSTEM \
    "${asad_ws}"/LANDSCAPE \
    "${asad_ws}"/DEPLOYER

#
# Clone Azure SAP Automated Deployment code repository
#
if [[ ! -d "${asad_dir}" ]]; then
    git clone "${asad_repo}" "${asad_dir}"
fi

#
# Clone Azure SAP Automated Deployment sample repository
#
if [[ ! -d "${asad_sample_dir}" ]]; then
    git clone "${asad_sample_repo}" "${asad_sample_dir}"
fi

#
# Install terraform for all users
#
sudo mkdir -p \
    "${tf_dir}" \
    "${tf_bin}"
wget -nv -O /tmp/"${tf_zip}" "https://releases.hashicorp.com/terraform/${tfversion}/${tf_zip}"
sudo unzip -o /tmp/"${tf_zip}" -d "${tf_dir}"
sudo ln -vfs "../$(basename "${tf_dir}")/terraform" "${tf_bin}/terraform"

sudo rm /tmp/"${tf_zip}"

# Uninstall Azure CLI - For some platforms
case "$(get_distro_name)" in
(ubuntu|sles)
  rel=$(lsb_release -a | grep Release | cut -d':' -f2 | xargs)
  # Ubuntu 20.04 (Focal Fossa) and 20.10 (Groovy Gorilla) include an azure-cli package with version 2.0.81 provided by the universe repository.
  # This package is outdated and not recommended. If this package is installed, remove the package
  if [ "$rel" == "20.04" ]; then
    echo "Removing Azure CLI"
    sudo apt remove azure-cli -y
    sudo apt autoremove -y
    sudo apt update -y
  fi
  if [ "$(get_distro_version)" == "15.3" ]; then
      set +o errexit
      sudo zypper rm -y --clean-deps azure-cli
      set -o errexit
  fi
  if [ "$(get_distro_version)" == "15.4" ]; then
      set +o errexit
      sudo zypper rm -y --clean-deps azure-cli
      set -o errexit
  fi
  if [ "$(get_distro_version)" == "15.5" ]; then
      set +o errexit
      sudo zypper rm -y --clean-deps azure-cli
      set -o errexit
  fi
  ;;
esac

# Install Azure CLI
case "$(get_distro_name)" in
(ubuntu)
    echo "Getting the Microsoft Key"
    sudo mkdir -p /etc/apt/keyrings
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
        sudo tee /etc/apt/sources.list.d/azure-cli.list

    sudo apt-get update
    sudo apt-get install azure-cli
    ;;
(sles)
    set +o errexit
    if [ -f /home/"${local_user}"/repos_configured ]; then
      sudo zypper install -y --from azure-cli azure-cli
    else
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      repo_found=$(zypper repos | grep "Azure CLI")
      if [ -z "$repo_found" ]; then
        sudo zypper addrepo --name 'Azure CLI' --check https://packages.microsoft.com/yumrepos/azure-cli azure-cli
      fi
      sudo touch /home/${local_user}/repos_configured
      sudo zypper install -y --from azure-cli azure-cli
    fi
    set -o errexit
    ;;
  (rhel*)
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
    sudo dnf install -y azure-cli
    ;;
esac

# sudo az upgrade --all --yes --only-show-errors --output none

export DOTNET_INSTALL_DIR=/opt/dotnet

sudo mkdir -p ${DOTNET_INSTALL_DIR}
export DOTNET_ROOT=${DOTNET_INSTALL_DIR}


# Install dotNet
case "$(get_distro_name)" in
(ubuntu)
    sudo snap install dotnet-sdk --classic --channel=7.0
    sudo snap alias dotnet-sdk.dotnet dotnet
    ;;
(sles)
    sudo wget https://dot.net/v1/dotnet-install.sh -O "/home/${local_user}/dotnet-install.sh"
    sudo chmod +x "/home/${local_user}/dotnet-install.sh"
    sudo /home/"${local_user}"/dotnet-install.sh --install-dir "${DOTNET_ROOT}" --channel 7.0
    ;;
  (rhel*)
    sudo wget https://dot.net/v1/dotnet-install.sh -O "/home/${local_user}/dotnet-install.sh"
    sudo chmod +x "/home/${local_user}/dotnet-install.sh"
    sudo /home/"${local_user}"/dotnet-install.sh --install-dir "${DOTNET_ROOT}" --channel 7.0
    ;;
esac

az config set extension.use_dynamic_install=yes_without_prompt

# Fail if any command exits with a non-zero exit status
set -o errexit

# Ensure our package metadata cache is up to date
# pkg_mgr_refresh
# pkg_mgr_upgrade
#
# Install latest Ansible revision of specified version for all users.

#
sudo mkdir -p \
  "${ansible_bin}" \
  "${ansible_collections}"


# Create a Python3 based venv into which we will install Ansible.
case "$(get_distro_name)" in
(ubuntu|sles)
    if [[ ! -e "${ansible_venv_bin}/activate" ]]; then
        sudo rm -rf "${ansible_venv}"
        sudo virtualenv --python python3 "${ansible_venv}"
    fi
    ;;
  (rhel*)
    if [[ ! -e "${ansible_venv_bin}/activate" ]]; then
        sudo rm -rf "${ansible_venv}"
        sudo python3 -m venv "${ansible_venv}"
        source "${ansible_venv_bin}/activate"
    fi
    ;;
esac



# Fail if pip3 doesn't exist in the venv
if [[ ! -x "${ansible_venv_bin}/pip3" ]]; then
    echo "Using the wrong pip3: '${found_pip3}' != '${ansible_venv_bin}/pip3'"
    exit 1
fi


# Ensure that standard tools are up to date
sudo "${ansible_venv_bin}"/pip3 install --upgrade \
    pip \
    wheel \
    setuptools

# Install latest MicroSoft Authentication Library
# TODO(rtamalin): Do we need this? In particular do we expect to integrated
# Rust based tools with the Python/Ansible envs that we are using?
# sudo ${ansible_venv_bin}/pip3 install \
#    setuptools-rust


# Install latest revision of target Ansible version, along with additional
# useful/supporting Python packages such as ansible-lint, yamllint,
# argcomplete, pywinrm.
# ansible-lint \
#  yamllint \

sudo "${ansible_venv_bin}"/pip3 install \
    "ansible-core>=${ansible_major}.${ansible_minor},<${ansible_major}.$((ansible_minor + 1))" \
    argcomplete \
    'pywinrm>=0.3.0' \
    netaddr  \
    jmespath


# Create symlinks for all relevant commands that were installed in the Ansible
# venv's bin so that they are available in the /opt/ansible/bin directory, which
# will be added to the system PATH. This ensures that we expose only those tools
# that we need from the Ansible venv bin directory without superceding standard
# system versions of the commands that are also found there, e.g. python3.
ansible_venv_commands=(
    # Ansible 2.9 command set
    ansible
    ansible-config
    ansible-connection
    ansible-console
    ansible-doc
    ansible-galaxy
    ansible-inventory
    ansible-playbook
    ansible-pull
    ansible-test
    ansible-vault

    # ansible-lint
    # ansible-lint

    # argcomplete
    activate-global-python-argcomplete

    # yamllint
    # yamllint
)


relative_path="$(realpath --relative-to ${ansible_bin} "${ansible_venv_bin}")"
for vcmd in "${ansible_venv_commands[@]}"
do
    sudo ln -vfs "${relative_path}/${vcmd}" "${ansible_bin}/${vcmd}"
done


# Ensure that Python argcomplete is enabled for all users interactive shell sessions
sudo "${ansible_bin}"/activate-global-python-argcomplete

# Install Ansible collections under the ANSIBLE_COLLECTIONS_PATHS for all users.
sudo mkdir -p "${ansible_collections}"
set +o xtrace

sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install ansible.windows --force --collections-path "${ansible_collections}"
sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install ansible.posix --force --collections-path "${ansible_collections}"
sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install ansible.utils --force --collections-path "${ansible_collections}"
sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install community.windows --force --collections-path "${ansible_collections}"
sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install microsoft.ad --force --collections-path "${ansible_collections}"

if [[ "${ansible_version}" == "2.11" ]]; then
  # ansible galaxy upstream has changed. Some collections are only available for install via old-galaxy.ansible.com
  # https://github.com/ansible/ansible/issues/81830
  # https://stackoverflow.com/questions/77225047/gitlab-pipeline-to-install-ansible-galaxy-role-fails/77238083#77238083
  echo "Installing some ansible collections from old-galaxy.ansible.com"
  sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install community.general --force --collections-path "${ansible_collections}" --server="https://old-galaxy.ansible.com" --ignore-certs
  sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install ansible.netcommon --force --collections-path "${ansible_collections}" --server="https://old-galaxy.ansible.com" --ignore-certs
else
  echo "Installing community.general"
  sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install community.general --force --collections-path "${ansible_collections}"
  echo "Installing ansible.netcommon:5.1.2"
  sudo -H "${ansible_venv_bin}/ansible-galaxy" collection install ansible.netcommon:5.1.2 --force --collections-path "${ansible_collections}"
fi
set -o xtrace
#
# Create /etc/profile.d script to setup environment for interactive sessions
#
echo '# Configure environment settings for deployer interactive sessions' | sudo tee /etc/profile.d/deploy_server.sh

export PATH="${PATH}":"${ansible_bin}":"${tf_bin}":"${DOTNET_ROOT}"

# Prepare Azure SAP Automated Deployment folder structure
mkdir -p \
    "${asad_ws}"/LOCAL/"${rg_name}" \
    "${asad_ws}"/LIBRARY \
    "${asad_ws}"/SYSTEM \
    "${asad_ws}"/LANDSCAPE \
    "${asad_ws}"/DEPLOYER/"${rg_name}"


chown -R "${USER}" "${asad_ws}"

#
# Update current session
#
echo '# Configure environment settings for deployer interactive session'

# Add new /opt bin directories to start of PATH to ensure the versions we installed
# are preferred over any installed standard system versions.

export ARM_SUBSCRIPTION_ID="${subscription_id}"
export DEPLOYMENT_REPO_PATH="$HOME/Azure_SAP_Automated_Deployment/sap-automation"

# Add new /opt bin directories to start of PATH to ensure the versions we installed
# are preferred over any installed standard system versions.

# Set env for ansible
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_COLLECTIONS_PATHS=~/.ansible/collections:"${ansible_collections}"

# Set env for MSI
export ARM_USE_MSI=true

#
# Create /etc/profile.d script to setup environment for future interactive sessions
#
export PATH="${PATH}":"${ansible_bin}":"${tf_bin}":"${HOME}"/Azure_SAP_Automated_Deployment/sap-automation/deploy/scripts:"${HOME}"/Azure_SAP_Automated_Deployment/sap-automation/deploy/ansible


echo "# Configure environment settings for deployer interactive sessions" | tee -a /tmp/deploy_server.sh

echo "export ARM_SUBSCRIPTION_ID=${subscription_id}" | tee -a /tmp/deploy_server.sh

# Replace with your actual agent directory
AGENT_DIR="/home/${USER}/agent"

# Check if the .agent file exists
if [ -f "$AGENT_DIR/.agent" ]; then

    devops_extension_installed=$(az extension list --query "[?name=='azure-devops'].name | [0]")
    if [ -z "$devops_extension_installed" ]; then
      az extension add --name azure-devops --output none
    fi

    echo "Azure DevOps Agent is configured."
    echo export "PATH=${ansible_bin}:${tf_bin}:${PATH}" | tee -a /tmp/deploy_server.sh

    devops_extension_installed=$(az extension list --query "[?name=='azure-devops'].name | [0]")
    if [ -z "$devops_extension_installed" ]; then
      az extension add --name azure-devops --output none
    fi

else
    echo "Azure DevOps Agent is not configured."

    echo "export SAP_AUTOMATION_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/sap-automation" | tee -a /tmp/deploy_server.sh
    echo "export DEPLOYMENT_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/sap-automation" | tee -a /tmp/deploy_server.sh
    echo "export CONFIG_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/WORKSPACES" | tee -a /tmp/deploy_server.sh

    echo export "PATH=${ansible_bin}:${tf_bin}:${PATH}:${HOME}/Azure_SAP_Automated_Deployment/sap-automation/deploy/scripts:${HOME}/Azure_SAP_Automated_Deployment/sap-automation/deploy/ansible" | tee -a /tmp/deploy_server.sh

    # Set env for MSI
    echo "export ARM_USE_MSI=true" | tee -a /tmp/deploy_server.sh

    /usr/bin/az login --identity 2>error.log || :
    # Ensure that the user's account is logged in to Azure with specified creds

    if [ ! -f error.log ]; then
      /usr/bin/az account show > az.json
      client_id=$(jq --raw-output .id az.json)
      tenant_id=$(jq --raw-output .tenantId az.json)
      rm az.json
    else
      client_id=''
      tenant_id=''
    fi

    if [ -n "${client_id}" ]; then
      export ARM_CLIENT_ID=${client_id}
      echo "export ARM_CLIENT_ID=${client_id}" | tee -a /tmp/deploy_server.sh
    fi

    # if [ -n "${tenant_id}" ]; then
    #   export ARM_TENANT_ID=${tenant_id}
    #   echo "export ARM_TENANT_ID=${tenant_id}" | tee -a /tmp/deploy_server.sh
    # fi
fi


# Set env for ansible
echo "export ANSIBLE_HOST_KEY_CHECKING=False" | tee -a /tmp/deploy_server.sh
echo "export ANSIBLE_COLLECTIONS_PATHS=${ansible_collections}" | tee -a /tmp/deploy_server.sh
echo "export BOM_CATALOG=${asad_sample_dir}/SAP" | tee -a /tmp/deploy_server.sh


# export DOTNET_ROOT
case "$(get_distro_name)" in
(ubuntu)
    echo "export DOTNET_ROOT=/snap/dotnet-sdk/current" | tee -a /tmp/deploy_server.sh
    ;;
(sles)
    echo "export DOTNET_ROOT=${DOTNET_ROOT}" | tee -a /tmp/deploy_server.sh
    ;;
(rhel*)
    ;;
esac

chown -R "${USER}" "${asad_home}"


# echo "export DOTNET_ROOT=/snap/dotnet-sdk/current" | tee -a /tmp/deploy_server.sh


# Ensure that the user's account is logged in to Azure with specified creds
echo 'az login --identity --output none' | tee -a /tmp/deploy_server.sh
# shellcheck disable=SC2016
echo 'echo ${USER} account ready for use with Azure SAP Automated Deployment' | tee -a /tmp/deploy_server.sh

sudo cp /tmp/deploy_server.sh /etc/profile.d/deploy_server.sh
sudo rm /tmp/deploy_server.sh

/usr/bin/az login --identity --output none
echo "${USER} account ready for use with Azure SAP Automated Deployment"

