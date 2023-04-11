param environmentName string
param location string = resourceGroup().location
param logAnalyticsCustomerId string
param logAnalyticsSharedKey string
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param storageAccountName string 

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: 'vnet-${resourceGroup().name}'
}

resource environment 'Microsoft.App/managedEnvironments@2023-02-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'consumption'
        workloadProfileType: 'Consumption'
      }
      {
        name: 'd4-compute'
        workloadProfileType: 'D4'
        MinimumCount: 1
        MaximumCount: 3
      }
    ]
    daprAIConnectionString: appInsightsConnectionString
    daprAIInstrumentationKey: appInsightsInstrumentationKey
    vnetConfiguration: {
      infrastructureSubnetId: '${vnet.id}/subnets/aca-apps'
      internal: true
    }
    zoneRedundant: false
  }
}

resource managedEnvStorage 'Microsoft.App/managedEnvironments/storages@2022-06-01-preview' = {
  name: storageAccountName
  parent: environment
  properties: {
    azureFile: {
      accessMode: 'ReadWrite'
      shareName: 'share'
      accountName: storage.name
      accountKey: listKeys(storage.id, storage.apiVersion).keys[0].value
    }
  }
}

output location string = location
output environmentId string = environment.id
output environmentStaticIp string = environment.properties.staticIp
output environmentDefaultDomain string = environment.properties.defaultDomain
