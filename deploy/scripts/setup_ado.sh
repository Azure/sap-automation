#!/bin/bash
# https://github.com/Microsoft/azure-pipelines-agent/releases

# ensure the agent will not be installed as root
if [ "$EUID" -eq 0 ]
then echo "Please run as normal user and not as root"
exit
fi

mkdir -p ~/agent; cd $_
wget https://aka.ms/AAftpys -O agent.tar.gz
tar zxvf agent.tar.gz


# run the configuration script
./config.sh

# automatic start configuration after VM reboot
sudo ./svc.sh install "${USER}"

# start the deamon
sudo ./svc.sh start
