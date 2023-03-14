param location string = resourceGroup().location
param storageAccountName string = 'files${uniqueString(resourceGroup().id)}' 

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
   name: storageAccountName
   location: location 
   sku: { 
     name: 'Standard_LRS' 
   } 
   kind: 'StorageV2' 
   properties: { 
     accessTier: 'Hot' 
     allowBlobPublicAccess: false
     minimumTlsVersion: 'TLS1_2'
     allowSharedKeyAccess: true
     supportsHttpsTrafficOnly: true
   } 
}

resource fileservices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: 'default'
  parent: storage
}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: 'share'
  parent: fileservices
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 1024
  }
}

output storageAccountName string = storage.name
// output storageAccountKey string = '${listKeys(storage.id, storage.apiVersion).keys[0].value}'
