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
		pywinrm[credssp] \
		setuptools --force
	ansible-galaxy collection install --force ansible.windows ansible.posix ansible.utils community.windows microsoft.ad community.general==11.4.1
	ansible --version
else
	echo "Running on SDAF deployed agent"

	isJmespathInstalled=$(which python3-jmespath || true)
	if [ -z "$isJmespathInstalled" ]; then
		echo -e "$green--- Install python3-jmespath ---$reset"
		sudo apt-get -qq -y install python3-jmespath
	fi


fi
