param environmentName string
param location string = resourceGroup().location
param appInsightsConnectionString string
param containerImage string
param serviceBusName string 
param useDapr bool = false

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusName
}

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: environmentName
}

resource mcmsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'messagecreator-msi'
  location: location
}

var messagePublisherlRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'

resource publisherRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().subscriptionId, mcmsi.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: messagePublisherlRoleDefinitionId
    principalId: mcmsi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource daprPublisherComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'publisher'
  parent: cappsEnv
  properties: {
    componentType: 'pubsub.azure.servicebus'
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
        value: mcmsi.properties.clientId
      }
    ]
    scopes: [
      'message-creator'
    ]
  }
}



// https://learn.microsoft.com/en-us/azure/templates/microsoft.app/containerapps?pivots=deployment-language-bicep
resource messagecreator 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: 'message-creator'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mcmsi.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', environmentName)
    workloadProfileName: 'consumption'
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: true    
        transport: 'Auto'
      }
      dapr: {
        enabled: useDapr
        appId: 'message-creator'
        appPort: 8080
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'message-creator'
          resources: {
            cpu: 1
            memory: '2Gi'
          } 
          probes: [
            {
              type: 'liveness'
              httpGet: {
                path: '/healthz'
                port: 8080
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/healthz'
                port: 8080
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
          ]
          env:[
            {
              name: 'PORT'
              value: '8080'
            }
            {
              name: 'VERSION'
              value: 'frontend - blue'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
            {
              name: 'ApplicationInsights__ConnectionString'
              value: appInsightsConnectionString
            }
          ]
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
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}
