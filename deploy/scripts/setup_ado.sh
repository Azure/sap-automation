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
sudo ./svc.sh install azureadm

# start the deamon
sudo ./svc.sh start

# Install dotnet for the web app
sudo snap install dotnet-sdk --classic --channel=3.1
sudo snap alias dotnet-sdk.dotnet dotnet
export DOTNET_ROOT=/snap/dotnet-sdk/current

# install mongosh for configuration management
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-mongosh