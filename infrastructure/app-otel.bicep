param environmentName string
param location string = resourceGroup().location
param containerImage string

resource otelmsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'otel-msi'
  location: location
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.app/containerapps?pivots=deployment-language-bicep
resource otel 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: 'otel'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${otelmsi.id}': {}
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
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'otel'
          resources: {
            cpu: 1
            memory: '2Gi'
          } 
        }        
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
