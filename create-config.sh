#!/bin/bash

set -e

# infrastructure deployment properties

PROJECT_NAME="$1" # here enter unique deployment name (ideally short and with letters for global uniqueness)

if [ "$PROJECT_NAME" == "" ]; then
echo "No project name provided - aborting"
exit 0;
fi

if [[ $PROJECT_NAME =~ ^[a-z0-9]{5,8}$ ]]; then
    echo "project name $PROJECT_NAME is valid"
else
    echo "project name $PROJECT_NAME is invalid - only numbers and lower case min 5 and max 8 characters allowed - aborting"
    exit 0;
fi

RESOURCE_GROUP="$PROJECT_NAME"

AZURE_CORE_ONLY_SHOW_ERRORS="True"

if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
    echo "resource group $RESOURCE_GROUP does not exist"
    error=1
else   
    echo "resource group $RESOURCE_GROUP already exists"
    LOCATION=$(az group show -n $RESOURCE_GROUP --query location -o tsv)
fi


AI_CONNECTIONSTRING=$(az resource show -g $RESOURCE_GROUP -n appi-$PROJECT_NAME --resource-type "Microsoft.Insights/components" --query properties.ConnectionString -o tsv | tr -d '[:space:]')
SB_CONNECTIONSTRING=$(az servicebus namespace authorization-rule keys list --name RootManageSharedAccessKey --namespace-name $PROJECT_NAME --resource-group $RESOURCE_GROUP --query "primaryConnectionString" | tr -d '"')

echo $AI_CONNECTIONSTRING
echo $SB_CONNECTIONSTRING

SB_CONNECTIONSTRING_ESC=$(echo "$SB_CONNECTIONSTRING" | sed 's/\//\\\//g')

cat template.env > local.env

replaces="s/{.serviceBusConnectionString}/$SB_CONNECTIONSTRING_ESC/;";

mkdir -p components

cat ./component-templates/queue-template.yaml | sed -e "$replaces" > ./components/queue.yaml

echo "ApplicationInsights__ConnectionString=\"$AI_CONNECTIONSTRING\"" >> local.env

echo "create component files in /components directory"