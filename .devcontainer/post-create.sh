#!/usr/bin/env bash

set -euo pipefail

# Install extra packages that don't have an extension
sudo apt update
sudo apt install -y \
    ansible-lint

# Create a log file for Ansible as defined in ansible.cfg (/var/tmp/ansible.log)
sudo touch /var/tmp/ansible.log
sudo chown vscode:vscode /var/tmp/ansible.log
