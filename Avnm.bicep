targetScope = 'subscription'
param location string
param shortLocationCode string
param avnmRgName string
param avnmName string
param spokeVNETids array
param hubVNETid string
param useHubGateway bool
param deployVnetPeeringMesh bool
param deployAvnmUDRs bool = false
param tagsByResource object = {}
param AzFwPrivateIP string
param userAssignedIdentityId string

resource avnmrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: avnmRgName
}

module avnmGroup 'modules/avnmgroup.bicep' = {
  scope: avnmrg
  name: 'AVNM-NetworkGroup-${shortLocationCode}'
  params: {
    avnmGroupName: '${avnmName}-NetworkGroup-${shortLocationCode}'
    avnmName: avnmName
    spokeVNETids: spokeVNETids
  }
}

module avnmConnectivityConfig 'modules/avnmconfigconnectivity.bicep' = {
  scope: avnmrg
  name: 'AVNM-ConnectivityConfig-${shortLocationCode}'
  params: {
    avnmName: avnmName
    avnmNetworkGroupID: avnmGroup.outputs.id
    avvmConnectivityConfigName: '${avnmName}-ConnectivityConfig-${shortLocationCode}'
    hubVNETid: hubVNETid
    useHubGateway: useHubGateway
    groupConnectivity: deployVnetPeeringMesh ? 'DirectlyConnected' : 'None'
  }
}

module avnmRoutingConfig 'modules/avnmconfigrouting.bicep' = if (deployAvnmUDRs) {
  scope: avnmrg
  name: 'AVNM-RoutingConfig-${shortLocationCode}'
  params: {
    avnmName: avnmName
    avnmNetworkGroupId: avnmGroup.outputs.id
    avnmRoutingConfigName: '${avnmName}-RoutingConfig-${shortLocationCode}'
    AzFwPrivateIP: AzFwPrivateIP
  }
}

module avnmConnectivityConfigDeployment 'modules/avnmdeployment.bicep' = {
  scope: avnmrg
  name: 'AVNM-ConnectivityConfig-Deployment-${shortLocationCode}'
  params: {
    avnmName: avnmName
    configType: 'Connectivity'
    configurationId: avnmConnectivityConfig.outputs.id
    deploymentScriptName: '${avnmName}-ConnectivityConfig-DeploymentScript-${shortLocationCode}'
    location: location
    userAssignedIdentityId: userAssignedIdentityId
    tagsByResource: tagsByResource
  }
}

module avnmRoutingConfigDeployment 'modules/avnmdeployment.bicep' = if (deployAvnmUDRs) {
  scope: avnmrg
  name: 'AVNM-RoutingConfig-Deployment-${shortLocationCode}'
  params: {
    avnmName: avnmName
    configType: 'Routing'
    configurationId: deployAvnmUDRs ? avnmRoutingConfig.outputs.id : ''
    deploymentScriptName: '${avnmName}-RoutingConfig-DeploymentScript-${shortLocationCode}'
    location: location
    userAssignedIdentityId: userAssignedIdentityId
    tagsByResource: tagsByResource
  }
}
