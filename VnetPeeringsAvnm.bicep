targetScope = 'subscription'
param location string
param HubResourceGroupName string
param avnmSubscriptionScopes array
param avnmName string = 'LabBuilder-AVNM'
param spokeVNETids array
param hubVNETid string
param useHubGateway bool
param deployVnetPeeringMesh bool
param tagsByResource object = {}

resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: HubResourceGroupName
}

module avnm 'modules/avnm.bicep' = {
  scope: hubrg
  name: 'AVNM'
  params: {
    avnmName: avnmName
    avnmSubscriptionScopes: avnmSubscriptionScopes
    location: location
    tagsByResource: tagsByResource
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
    tagsByResource: tagsByResource
  }
}

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
    tagsByResource: tagsByResource
  }
}
