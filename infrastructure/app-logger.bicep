param environmentName string
param location string = resourceGroup().location
param containerImage string
param keyVaultName string

resource loggermsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'logger-msi'
  location: location
}

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

// resource mipolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
//   name: 'add'
//   parent: kv
//   properties: {
//     accessPolicies: [
//       {
//         applicationId: '${loggermsi.properties.principalId}'
//         permissions: {
//           secrets: [
//             'get'
//           ]
//         }
//         tenantId: '${subscription().tenantId}'
//       }
//     ]
//   }
// }

resource loggermsiacr 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: 'logger-acr'
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.app/containerapps?pivots=deployment-language-bicep
resource loggers 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: 'logger'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${loggermsiacr.id}': {}
      '${loggermsi.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', environmentName)
    workloadProfileName: 'consumption'
    configuration: {
      secrets: [
        {
            name: 'kvalue'
            keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/demovalue'
            identity: '${loggermsi.id}'
        }]
      // registries: [ {
      //   server: 'dzreg1.azurecr.io'
      //   identity: loggermsiacr.id
      // }        
      // ]
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: true    
        transport: 'Auto'
      }
      dapr: {
        enabled: true
        appId: 'logger'
        appPort: 80
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'explorer'
          resources: {
            cpu: 1
            memory: '2Gi'
          } 
          probes: [
            {
              type: 'liveness'
              httpGet: {
                path: '/healthz'
                port: 80
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/healthz'
                port: 80
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
          ]
          env:[
            {
              name: 'PORT'
              value: '80'
            }
            {
              name: 'NAME'
              value: 'aca-dummy'
            }
            {
              name: 'KV'
              secretRef: 'kvalue'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
