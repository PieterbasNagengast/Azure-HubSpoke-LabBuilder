targetScope = 'subscription'
param location string
param HubResourceGroupName string
param avnmSubscriptionScopes array
param avnmName string = 'LabBuilder-AVNM'
param spokeVNETids array
param hubVNETid string
param useHubGateway bool
param deployVnetPeeringMesh bool
param deployAvnmUDRs bool = false
param tagsByResource object = {}
param AzFwPrivateIP string

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

module avnmRoutingConfig 'modules/avnmroutingconfig.bicep' = if (deployAvnmUDRs) {
  scope: hubrg
  name: 'AVNM-RoutingConfig'
  params: {
    avnmName: avnm.outputs.name
    avnmNetworkGroupId: avnmGroup.outputs.id
    AzFwPrivateIP: AzFwPrivateIP
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

module avnmConnectivityConfigDeployment 'modules/avnmdeployment.bicep' = {
  scope: hubrg
  name: 'AVNM-ConnectivityConfig-Deployment'
  params: {
    avnmName: avnm.outputs.name
    configType: 'Connectivity'
    configurationId: avnmConnectivityConfig.outputs.id
    deploymentScriptName: '${avnm.outputs.name}-ConnectivityConfig-DeploymentScript'
    location: location
    userAssignedIdentityId: userAssignedIdentity.outputs.id
    tagsByResource: tagsByResource
  }
}

module avnmRoutingConfigDeployment 'modules/avnmdeployment.bicep' = {
  scope: hubrg
  name: 'AVNM-RoutingConfig-Deployment'
  params: {
    avnmName: avnm.outputs.name
    configType: 'Routing'
    configurationId: deployAvnmUDRs ? avnmRoutingConfig.outputs.id : ''
    deploymentScriptName: '${avnm.outputs.name}-RoutingConfig-DeploymentScript'
    location: location
    userAssignedIdentityId: userAssignedIdentity.outputs.id
    tagsByResource: tagsByResource
  }
}
