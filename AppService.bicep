param appName string
param aspName string
param location string

param linuxFxVersion string = 'NODE|18-lts'
param tags object = {}

@allowed([
  'Linux'
  'Windows'
])
param OS string = 'Linux'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: aspName
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  tags: tags
  properties: {
    siteConfig: {
      appSettings: []
      linuxFxVersion: (OS == 'Linux') ? linuxFxVersion : ''
      alwaysOn: true
      ftpsState: 'FtpsOnly'
    }
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
  }
}

resource linuxConfig 'Microsoft.Web/sites/config@2022-03-01' = if (OS == 'Linux') {
  name: 'web'
  parent: appService
  properties: {
    javaContainer: 'TOMCAT'
    javaContainerVersion: '10.0'
    javaVersion: '11.0.14'
    appCommandLine: 'pm2 serve /home/site/wwwroot --no-daemon'
  }
}

// No additional config required for .NET

output appName string = appService.name
output appURL string = appService.properties.defaultHostName
