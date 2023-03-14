param environmentName string
param location string = resourceGroup().location
param appInsightsConnectionString string
param containerImage string
param storageAccountName string 

resource expmsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'explorer-msi'
  location: location
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.app/containerapps?pivots=deployment-language-bicep
resource explorer 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: 'explorer'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${expmsi.id}': {}
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
        appId: 'explorer'
        appPort: 8080
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
                path: '/ping'
                port: 3000
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/ping'
                port: 3000
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
          ]
          env:[
            {
              name: 'PORT'
              value: '3000'
            }
            {
              name: 'VERSION'
              value: 'latest'
            }
            {
              name: 'WRITEPATH'
              value: '/data'
            }
            {
              name: 'AIC_STRING'
              value: appInsightsConnectionString
            }
          ]
          volumeMounts: [
            {
              volumeName: 'share'
              mountPath: '/data'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'share'
          storageName: storageAccountName
          storageType: 'AzureFile'
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
