param creatorImageTag string 
param receiverImageTag string
param containerRegistryOwner string

@description('Location resources.')
param location string = resourceGroup().location

@description('Specifies a project name that is used to generate the Event Hub name and the Namespace name.')
param projectName string

module logging 'logging.bicep' = {
  name: 'logging'
  params: {
    location: location
    logAnalyticsWorkspaceName: 'log-${projectName}'
    applicationInsightsName: 'appi-${projectName}'
  }
}

module environment 'environment.bicep' = {
  name: 'container-app-environment'
  params: {
    environmentName: projectName
    logAnalyticsCustomerId: logging.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: logging.outputs.logAnalyticsSharedKey
    appInsightsInstrumentationKey: logging.outputs.appInsightsInstrumentationKey
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
  }
}

module servicebus 'servicebus.bicep' = {
  name: 'servicebus'
  params: {
    serviceBusName: projectName
  }
}


module pubsub 'aca-pubsub.bicep' = {
  name: 'aca-pubsub'
  params: {
    environmentName: projectName
    serviceBusName: projectName
  }
}

module messagecreator 'app-creator.bicep' = {
  name: 'container-app-js-calc-backend'
  params: {
    containerImage: 'ghcr.io/${containerRegistryOwner}/aca-dapr/message-creator:${creatorImageTag}'
    environmentName: projectName
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    serviceBusName: projectName
  }
}

module messagereceiver 'app-receiver.bicep' = {
  name: 'container-app-js-calc-frontend'
  params: {
    containerImage: 'ghcr.io/${containerRegistryOwner}/aca-dapr/message-receiver:${receiverImageTag}'
    environmentName: projectName
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    serviceBusName: projectName
  }
}


// az deployment group create -g dzca15cgithub -f ./deploy/apps.bicep -p explorerImageTag=latest -p calculatorImageTag=latest  -p containerRegistryOwner=denniszielke
