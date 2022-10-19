param environmentName string
param serviceBusName string 

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusName
}

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: environmentName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'pubsub'
  parent: cappsEnv
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'sb-root-connectionstring'
      }
    ]
    secrets: [
      {
        name: 'sb-root-connectionstring'
        value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
      }
    ]
    scopes: [
      'message-creator'
      'message-receiver'
    ]
  }
}
