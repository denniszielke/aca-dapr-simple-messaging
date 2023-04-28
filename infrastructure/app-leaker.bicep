param environmentName string
param location string = resourceGroup().location
param containerImage string

resource leakermsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'leaker-msi'
  location: location
}

var metricsPublisherlRoleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb'

resource metricsRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().subscriptionId, leakermsi.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: metricsPublisherlRoleDefinitionId
    principalId: leakermsi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.app/containerapps?pivots=deployment-language-bicep
resource leaker 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: 'leaker'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${leakermsi.id}': {}
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
        enabled: true
        appId: 'leaker'
        appPort: 8080
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'leaker'
          resources: {
            cpu: 3
            memory: '7Gi'
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
              name: 'LEAK'
              value: 'true'
            }
          ]
        }
        {
          image: 'denniszielke/telegraf:opt'
          name: 'telegraf'
          terminationGracePeriodSeconds: 5
          resources: {
            cpu: 1
            memory: '1Gi'
          }          
          env:[
            {
              name: 'AZURE_TENANT_ID'
              value: '${subscription().tenantId}'
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: leakermsi.properties.clientId
            }
            {
              name: 'RESOURCE_ID'
              value: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.App/containerapps/leaker'
            }
            {
              name: 'LOCATION'
              value: location
            }
            {
              name: 'INSTANCE'
              value: 'leaker'
            }
            {
              name: 'PROMETHEUS_URL'
              value: 'http://localhost:8080/metrics'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'memoryscalingrule'
            custom: {
              type: 'memory'
              metadata: {
                type: 'Utilization'
                value: '20'
              }
            }
          }
        ]
      }
    }
  }
}
