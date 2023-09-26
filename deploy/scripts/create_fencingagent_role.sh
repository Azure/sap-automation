#!/bin/bash
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                                  Create Fencing Role definition                       #"
echo "#                                                                                       #"
echo "#########################################################################################"

echo "Subscription $ARM_SUBSCRIPTION_ID"

if [ -z $ARM_SUBSCRIPTION_ID ]; then
    read -r -p "subscription: " ARM_SUBSCRIPTION_ID
fi

sub=/subscriptions/$ARM_SUBSCRIPTION_ID

role=$(az role definition list --custom-role-only true --output json --query '[].{roleName:roleName, roleType:roleType}' | grep 'Linux Fence Agent Role')

if [ -z $role ] ; then
    echo $(jq --arg sub $sub '.assignableScopes |= [$sub]' ./templates/fencing.json)  > temp_fencing.json

    az role definition create --role-definition ./temp_fencing.json --subscription $ARM_SUBSCRIPTION_ID

    rm ./temp_fencing.json
fi
