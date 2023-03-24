param location string
param classCode string
@minValue(1)
param planIndex int

param tags object = {}

@allowed([
  'linux'
  'windows'
])
param OS string = 'linux'

var planIndexFormatted = padLeft(planIndex, length(string(planIndex)), '0')
var aspName = 'asp-${classCode}-${planIndexFormatted}'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: aspName
  location: location
  tags: tags
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  kind: (OS == 'linux') ? OS : 'app'
  properties: {
    reserved: true
  }
}


