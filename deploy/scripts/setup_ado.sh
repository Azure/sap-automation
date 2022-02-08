#!/bin/bash
# https://github.com/Microsoft/azure-pipelines-agent/releases

# ensure the agent will not be installed as root
if [ "$EUID" -eq 0 ]
then echo "Please run as normal user and not as root"
exit
fi

mkdir -p ~/agent; cd $_
wget https://vstsagentpackage.azureedge.net/agent/2.196.1/vsts-agent-linux-x64-2.196.1.tar.gz -O agent.tar.gz
tar zxvf agent.tar.gz

# run the configuration script
./config.sh  

# automatic start configuration after VM reboot
sudo ./svc.sh install azureadm

# start the deamon
sudo ./svc.sh start

# install dotnet for the web app
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-3.1
