targetScope = 'subscription'
param location string
param HubResourceGroupName string
param avnmSubscriptionScopes array
param avnmName string = 'LabBuilder-AVNM'
param spokeVNETids array
param hubVNETid string
param useHubGateway bool
param deployVnetPeeringMesh bool

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: HubResourceGroupName
}

module avnm 'modules/avnm.bicep' = {
  scope: hubrg
  name: 'AVNM'
  params: {
    avnmName: avnmName
    avnmSubscriptionScopes: avnmSubscriptionScopes
    location: location
  }
}

module avnmGroup 'modules/avnmgroup.bicep' = {
  scope: hubrg
  name: 'AVNM-NetworkGroup'
  params: {
    avnmGroupName: '${avnm.outputs.name}-NetworkGroup01'
    avnmName: avnm.outputs.name
    spokeVNETids: spokeVNETids
  }
}

module avnmConnectivityConfig 'modules/avnmconfig.bicep' = {
  scope: hubrg
  name: 'AVNM-ConnectivityConfig'
  params: {
    avnmName: avnm.outputs.name
    avnmNetworkGroupID: avnmGroup.outputs.id
    avvmConnectivityConfigName: '${avnm.outputs.name}-ConnectivityConfig'
    hubVNETid: hubVNETid
    useHubGateway: useHubGateway
    groupConnectivity: deployVnetPeeringMesh ? 'DirectlyConnected' : 'None'
  }
}

module userAssignedIdentity 'modules/uai.bicep' = {
  scope: hubrg
  name: 'UserAssignedIdentityForAVNM'
  params: {
    location: location
    uaiName: avnm.outputs.name
  }
}

// 'Microsoft.Resources/subscriptions/read' -> On Resource Group

// Deployment failed with error: 
// The client 'b4446e76-50c2-409c-bb15-d5047e3c59e2' 
// with object id 'b4446e76-50c2-409c-bb15-d5047e3c59e2' 
// does not have authorization to 
// perform action 'Microsoft.Network/networkManagers/commit/action' 
// over scope '/subscriptions/aa66b139-0ef4-4018-8aa7-b9510bea120a/resourceGroups/LabBuilderValidation-hub/providers/Microsoft.Network/networkManagers/LabBuilder-AVNM'

module roleAssignment 'modules/avnmroleassignment.bicep' = {
  scope: hubrg
  name: 'RoleAssignmentForAVNMDeploymentScript'
  params: {
    principalID: userAssignedIdentity.outputs.principalID
    avnmName: avnm.outputs.name
  }
}

module avnmConfigDeployment 'modules/avnmdeployment.bicep' = {
  scope: hubrg
  name: 'AVNM-ConfigurationDeployment'
  params: {
    avnmName: avnm.outputs.name
    configType: 'Connectivity'
    configurationId: avnmConnectivityConfig.outputs.id
    deploymentScriptName: '${avnm.outputs.name}-DeploymentScript'
    location: location
    userAssignedIdentityId: userAssignedIdentity.outputs.id
  }
}
