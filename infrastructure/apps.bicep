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
    environmentName: '${projectName}'
    logAnalyticsCustomerId: logging.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: logging.outputs.logAnalyticsSharedKey
    appInsightsInstrumentationKey: logging.outputs.appInsightsInstrumentationKey
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    storageAccountName: storage.outputs.storageAccountName
  }
}

module servicebus 'servicebus.bicep' = {
  name: 'servicebus'
  params: {
    serviceBusName: 'sb-${projectName}'
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
}

module messagecreator 'app-creator.bicep' = {
  name: 'container-app-creator'
  params: {
    containerImage: 'ghcr.io/${containerRegistryOwner}/aca-dapr/message-creator:${creatorImageTag}'
    environmentName: '${projectName}'
    serviceBusName: projectName
  }
}

module messagereceiver 'app-receiver.bicep' = {
  name: 'container-app-receiver'
  params: {
    containerImage: 'ghcr.io/${containerRegistryOwner}/aca-dapr/message-receiver:${receiverImageTag}'
    environmentName: '${projectName}'
    serviceBusName: projectName
  }
}

module explorer 'app-explorer.bicep' = {
  name: 'container-app-explorer'
  params: {
    containerImage: 'ghcr.io/denniszielke/container-apps/js-dapr-explorer:latest'
    environmentName: '${projectName}'
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    storageAccountName: storage.outputs.storageAccountName
  }
}

module logger 'app-otel.bicep' = {
  name: 'container-app-logger'
  params: {
    environmentName: '${projectName}'
    containerImage: 'testcontainerregistrymichdai.azurecr.io/oteldemoimage:latest' // 'dzreg1.azurecr.io/dummy-logger:top'
  }
}

// module logger 'app-logger.bicep' = {
//   name: 'container-app-logger'
//   params: {
//     environmentName: '${projectName}'
//     containerImage: 'ghcr.io/denniszielke/demos/js-dummy-logger:latest' // 'dzreg1.azurecr.io/dummy-logger:top'
//     keyVaultName: 'kvd${projectName}'
//   }
// }

// module leaker 'app-leaker.bicep' = {
//   name: 'container-app-leaker'
//   params: {
//     environmentName: '${projectName}'
//     containerImage: 'ghcr.io/denniszielke/demos/js-crashing-app:4805887323'
//   }
// }


// az deployment group create -g dzca15cgithub -f ./deploy/apps.bicep -p explorerImageTag=latest -p calculatorImageTag=latest  -p containerRegistryOwner=denniszielke
