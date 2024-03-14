param environmentName string
param location string = resourceGroup().location
param containerImage string
param serviceBusName string 

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusName
}

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: environmentName
}

resource nginxmsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'nginx-msi'
  location: location
}

var messagePublisherlRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'

resource publisherRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().subscriptionId, nginxmsi.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: messagePublisherlRoleDefinitionId
    principalId: nginxmsi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource daprPublisherComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'publisher'
  parent: cappsEnv
  properties: {
    componentType: 'pubsub.azure.servicebus.queues'
    version: 'v1'
    metadata: [
      {
        name: 'namespaceName'
        value: 'sb-${serviceBus.name}.servicebus.windows.net'
      }
      {
        name: 'azureEnvironment'
        value: 'AZUREPUBLICCLOUD'
      }
      {
        name: 'azureTenantId'
        value: tenant().tenantId
      }      
      {
        name: 'azureClientId'
        value: nginxmsi.properties.clientId
      }
    ]
    scopes: [
      'nginx'
    ]
  }
}


// https://learn.microsoft.com/en-us/azure/templates/microsoft.app/containerapps?pivots=deployment-language-bicep
resource nginx 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: 'nginx'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${nginxmsi.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', environmentName)
    workloadProfileName: 'consumption'
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: true    
        transport: 'Auto'
      }
      dapr: {
        enabled: true
        appId: 'nginx'
        appPort: 80
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'nginx'
          resources: {
            cpu: 1
            memory: '2Gi'
          } 
        }        
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 4
        rules: [
          {
            name: 'backendrule'
            custom: {
              type: 'http'
              metadata: {
                concurrentRequests: '500'
              }
            }
          }
        ]
      }
    }
  }
}
