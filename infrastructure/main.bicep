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
    environmentName: 'a${projectName}'
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
