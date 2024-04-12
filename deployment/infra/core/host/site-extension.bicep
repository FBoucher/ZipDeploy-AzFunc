metadata description = 'Creates an Azure Apps extension for ZipDeploy.'
param functionAppName string
param location string = resourceGroup().location

// The URI of the zip package to deploy. Must be publicly accessible.
param packageUri string


resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = if (!(empty(functionAppName))) {
  name: functionAppName
}

resource azFunc_ZipDeploy 'Microsoft.Web/sites/extensions@2021-03-01' = {
  parent: functionApp
  name: 'zipdeploy'
  properties: {
    packageUri: packageUri
  }
}
