metadata description = 'Creates an Azure App Service plan.'
param name string
param location string = resourceGroup().location
param tags object = {}
param sku object

// WINDOWS Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    computeMode: 'Dynamic'
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
