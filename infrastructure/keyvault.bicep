@description('Specifies the Azure location for all resources.')
param location string = resourceGroup().location

param keyVaultName string

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: '${subscription().tenantId}'
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      
    ]
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: 'demovalue'
  properties: {
    value: 'secretValue'
  }
}
