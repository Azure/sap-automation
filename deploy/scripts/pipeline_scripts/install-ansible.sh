#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

if [ ! -f "/etc/profile.d/deploy_server.sh" ]; then

	sudo apt install python3-jmespath -y

	pip3 uninstall -y ansible-core --verbose

	pip3 install ansible-core=="${ansible_core_version:-2.16.14}" \
		argcomplete \
		'pywinrm>=0.3.0' \
		netaddr \
		wheel \
		setuptools --force
	ansible-galaxy collection install --force ansible.windows ansible.posix ansible.utils community.windows microsoft.ad community.general
	ansible --version
else
	echo "Running on SDAF deployed agent"
	sudo apt install python3-jmespath -y
fi
