#!/bin/bash

# https://github.com/Microsoft/azure-pipelines-agent/releases

  mkdir -p ~/agent; cd $_

  wget https://vstsagentpackage.azureedge.net/agent/2.196.1/vsts-agent-linux-x64-2.196.1.tar.gz agent.tar.gz

  tar zxvf agent.tar.gz

  ./config.sh
  sudo ./svc.sh install azureadm
  sudo ./svc.sh start

