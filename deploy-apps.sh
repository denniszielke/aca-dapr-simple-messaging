#!/bin/bash

set -e

# infrastructure deployment properties
PROJECT_NAME="$1"
REGISTRY_OWNER="$2"
IMAGE_TAG="$3"

if [ "$PROJECT_NAME" == "" ]; then
echo "No project name provided - aborting"
exit 0;
fi

if [ "$REGISTRY_OWNER" == "" ]; then
echo "No registry provided - aborting"
exit 0;
fi

if [ "$IMAGE_TAG" == "" ]; then
echo "No tag provided - defaulting to latest"
IMAGE_TAG="latest"
fi

if [[ $PROJECT_NAME =~ ^[a-z0-9]{5,10}$ ]]; then
    echo "project name $PROJECT_NAME is valid"
else
    echo "project name $PROJECT_NAME is invalid - only numbers and lower case min 5 and max 10 characters allowed - aborting"
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

az deployment group create -g $RESOURCE_GROUP -f ./infrastructure/apps.bicep \
          -p projectName=$PROJECT_NAME -p creatorImageTag=$IMAGE_TAG -p receiverImageTag=$IMAGE_TAG \
          -p containerRegistryOwner=$REGISTRY_OWNER



