targetScope = 'subscription'
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@maxLength(64)
@description('FunctionApp Name')
param appName string

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))


var functionAppName = '${abbrs.webSitesFunctions}${appName}${resourceToken}'
var storageAccountName = '${abbrs.storageStorageAccounts}${toLower(substring(appName, 0, min(length(appName), 9)))}${resourceToken}'
var packageUri = 'https://github.com/FBoucher/ZipDeploy-AzFunc/releases/download/v1/ZipDeploy-package-v1.zip'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}


module servicePlan 'core/host/appserviceplan.bicep' = {
  scope: rg
  name: 'appserviceplan'
  params: {
    name: '${abbrs.webServerFarms}${appName}${resourceToken}'
    location: location
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
    tags: tags
  }
}

module storageAccount 'core/storage/storage-account.bicep' = {
  scope: rg
  name: 'storageaccount'
  params: {
    name: storageAccountName
    location: location
    tags: tags
  }
}


module logAnalytics 'core/monitor/loganalytics.bicep' = {
  scope: rg
  name: 'loganalytics'
  params: {
    name: '${abbrs.analysisServicesServers}${appName}${resourceToken}'
    location: location
    tags: tags
  }
}


module applicationInsights 'core/monitor/applicationinsights.bicep' = {
  scope: rg
  name: 'applicationinsights'
  params: {
    name: '${abbrs.insightsComponents}${appName}${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    dashboardName: appName
  }
}


module functionApp 'core/host/functions.bicep' = {
  name: 'functionApp'
  scope: rg
  params: {
    name: functionAppName
    location: location
    appServicePlanId: servicePlan.outputs.id
    runtimeName: 'dotnet-isolated'
    extensionVersion:'~4'
    storageAccountName: storageAccount.outputs.name
    applicationInsightsName:  applicationInsights.outputs.name
    tags: tags
    managedIdentity: true 
    appSettings:{
      WEBSITE_RUN_FROM_PACKAGE: 1
    }
  }
  dependsOn: [
    servicePlan
    storageAccount
    applicationInsights
  ]
}


module azFuncZipDeploy 'core/host/site-extension.bicep' = {
  name: 'azFuncZipDeploy'
  scope: rg
  params: {
    functionAppName: functionAppName
    location: location
    packageUri: packageUri
  }
  dependsOn: [
    functionApp
  ]
}


output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_FUNCTIONAPP_URI string = functionApp.outputs.uri
output STORAGE_ACCOUNT_NAME string = storageAccountName 
