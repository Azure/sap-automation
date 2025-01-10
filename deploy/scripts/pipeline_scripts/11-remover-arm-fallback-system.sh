#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors --output none

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  debug=true
  export debug
fi

ENVIRONMENT=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
echo "Environment:                           $ENVIRONMENT"

LOCATION=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
echo
echo "Location:                              $LOCATION"

NETWORK=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $3}' | xargs)
echo "Network:                               $NETWORK"


SID=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $4}' | xargs)
echo "SID:                                   $SID"

cd "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit

echo "##vso[build.updatebuildnumber]Removing SAP System zone $SAP_SYSTEM_FOLDERNAME"
changed=0

git checkout -q "$BUILD_SOURCEBRANCHNAME"
git clean -d -f -X

if [ -f ".terraform/terraform.tfstate" ]; then
  git rm --ignore-unmatch -q --ignore-unmatch ".terraform/terraform.tfstate"
  changed=1
fi

if [ -d ".terraform" ]; then
  git rm -q -r --ignore-unmatch ".terraform"
  changed=1
fi

if [ -f "$SAP_SYSTEM_TFVARS_FILENAME" ]; then
  git add "$SAP_SYSTEM_TFVARS_FILENAME"
  changed=1
fi

if [ -f "sap-parameters.yaml" ]; then
  git rm --ignore-unmatch -q "sap-parameters.yaml"
  changed=1
fi

if [ -f "${SID}_hosts.yaml" ]; then
  git rm --ignore-unmatch -q "${SID}_hosts.yaml"
  changed=1
fi

if [ -f "${SID}.md" ]; then
  git rm --ignore-unmatch -q "${SID}.md"
  changed=1
fi

if [ -f "${SID}_inventory.md" ]; then
  git rm --ignore-unmatch -q "${SID}_inventory.md"
  changed=1
fi

if [ -f "${SID}_virtual_machines.json" ]; then
  git rm --ignore-unmatch -q "${SID}_virtual_machines.json"
  changed=1
fi

if [ -d "logs" ]; then
  git rm -q -r --ignore-unmatch "logs"
  changed=1
fi

if [ 1 == $changed ]; then
  git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
  git config --global user.name "$BUILD_REQUESTEDFOR"

  if git commit -m "Infrastructure for $SAP_SYSTEM_TFVARS_FILENAME removed. [skip ci]"; then
    if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
      echo "##vso[task.logissue type=warning]Removal of $SAP_SYSTEM_TFVARS_FILENAME updated in $BUILD_BUILDNUMBER"
    else
      echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
    fi
  fi
fi
exit $return_code
