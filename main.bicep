targetScope = 'subscription'

// REQUIRED PARAMETERS
param resourceGroupName string = 'CS101-FA21'
param classCode string = 'CS101-FA21'
@minValue(1)
param studentCount int = 6

// OPTIONAL PARAMETERS
param location string = 'eastus'
@allowed([
  'linux'
  'windows'
])
param OS string = 'linux'
param linuxFxVersion string = 'NODE|14-lts'
@minValue(1)
@maxValue(100)
param maxAppsPerPlan int = 3
param dateCreatedTagValue string = utcNow('yyyy-MM-dd')
param tags object = {}

// VARIABLES
var defaultTags = {
  'date-created': dateCreatedTagValue
  lifetime: 'medium'
  purpose: 'demo'
  OS: OS
}

var actualTags = union(tags, defaultTags)

// Calculate the number of App Service Plans required
var plansRequired = ((studentCount / maxAppsPerPlan) + ((studentCount % maxAppsPerPlan) > 0 ? 1 : 0))
// Calculate the average required apps per plan
var avgAppsPerPlan = studentCount / plansRequired
// Calculate the number of apps to be deployed in each plan
var actualAppsPerPlan = [for i in range(1, plansRequired): (studentCount / plansRequired + ((plansRequired * avgAppsPerPlan < studentCount) && (studentCount - plansRequired * avgAppsPerPlan >= i) ? 1 : 0))]

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

var appServices = [for i in range(1, studentCount):{
  planIndex: i % (studentCount/maxAppsPerPlan) + 1
  appIndex: i % studentCount/plansRequired + 1
}]

module appServiceAndPlanModule 'AppServicePlan.bicep' = [for i in range(1, plansRequired): {
  name: 'appServiceAndPlan-${classCode}-${i}'
  scope: resourceGroup
  params: {
    location: location
    planIndex: i
    classCode: classCode
    tags: actualTags
  }
}]

module appServiceModule 'AppService.bicep' = [for (app, i) in appServices: {
  name: 'appService-${classCode}-${i}'
  scope: resourceGroup
  params: {
    appName: 'app-${classCode}-${app.planIndex}-${padLeft(app.appIndex, 2, '0')}' // fixed width padding 2 or 3.
    aspName: 'asp-${classCode}-${app.planIndex}'
    location: location
    linuxFxVersion: linuxFxVersion
    tags: tags
  }
  dependsOn: [
    appServiceAndPlanModule[app.planIndex-1]
  ]
}]

// For verification, ensure that the number of apps matches the number of students
var numberOfAppsCalculated = reduce(actualAppsPerPlan, 0, (cur, prev) => cur + prev)

//output hostNamesToFlat array = flatten([for i in range(0, plansRequired): appServiceAndPlan[i].outputs.hostNames])

output plansRequired int = plansRequired
output avgAppsPerPlan int = avgAppsPerPlan
output actualAppsPerPlan array = actualAppsPerPlan
output numberOfAppsCalculated int = numberOfAppsCalculated
output numberOfAppsMatchesStudentCount bool = (studentCount == numberOfAppsCalculated)

//output flatHostNames array = [for i in range(0, plansRequired): reduce(appServiceAndPlanModule[i].outputs.hostNames, null, (previous, current) => '${previous},${current}')]
//output hostNames array = [for i in range(0, plansRequired): appServiceAndPlanModule[i].outputs.hostNames]
// output appNames array = [for i in range(0, plansRequired): appServiceAndPlanModule[i].outputs.appNames]
// output aspNames array = [for i in range(0, plansRequired): appServiceAndPlanModule[i].outputs.appServicePlanName]
//output hostNames array = map(reduce(appServiceAndPlan, [], ), arg => arg.outputs.hostNames)

var appServicesSorted = sort(appServices, (a, b) => a.planIndex < b.planIndex)
output appServicesstructure array = sort(appServicesSorted, (d,f) => d.appIndex < f.appIndex)
output appServices array = [for (app, i) in appServices: appServiceModule[i].outputs.appName]
output appServicesHostNames array = [for (app, i) in appServices: appServiceModule[i].outputs.appURL]
