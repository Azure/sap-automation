#!/usr/bin/env bash

set -euo pipefail

# Install extra packages that don't have an extension
sudo apt update
sudo apt install -y \
    ansible-lint

# Create a log file for Ansible as defined in the ansible.cfg in /deploy/ansible
sudo touch /var/log/ansible.log
sudo chown vscode:vscode /var/log/ansible.log
