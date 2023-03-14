param environmentName string
param location string = resourceGroup().location
param appInsightsConnectionString string
param containerImage string
param serviceBusName string 

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusName
}

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: environmentName
}

resource mrmsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'messagereceiver-msi'
  location: location
}

var messageReceiverRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

resource receiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().subscriptionId, mrmsi.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: messageReceiverRoleDefinitionId
    principalId: mrmsi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource daprReceiverComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'pubsub'
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
        value: mrmsi.properties.clientId
      }
    ]
    scopes: [
      'message-receiver'
    ]
  }
}

resource messagereceiver 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: 'message-receiver'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mrmsi.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', environmentName)
    workloadProfileType: 'Consumption'
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: true    
        transport: 'Auto'
      }
      dapr: {
        enabled: true
        appId: 'message-receiver'
        appPort: 8080
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'message-receiver'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          probes: [
            {
              type: 'liveness'
              httpGet: {
                path: '/ping'
                port: 8080
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/ping'
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
        minReplicas: 0
        maxReplicas: 4
        // rules: [
        //   {
        //     name: 'service-bus-scale-rule'
        //     custom: {
        //       type: 'azure-servicebus'
        //       metadata: {
        //         topicName: 'events'
        //         subscriptionName: 'receiver-service'
        //         messageCount: '10'
        //       }
        //       auth: [
        //         {
        //           secretRef: 'sb-root-connectionstring'
        //           triggerParameter: 'connection'
        //         }
        //       ]
        //     }
        //   }
        // ]
      }
    }
  }
}
