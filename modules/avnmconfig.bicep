param avnmName string
param avvmConnectivityConfigName string

@allowed([
  'HubAndSpoke'
  'Mesh'
])
param connectivityTopology string = 'HubAndSpoke'

param deleteExistingPeering bool = false
param isGlobal bool = false

param hubVNETid string
param avnmNetworkGroupID string

@allowed([
  'None'
  'DirectlyConnected'
])
param groupConnectivity string = 'None'
param useHubGateway bool = false

resource avnmConnectivityConfig 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-11-01' = {
  name: '${avnmName}/${avvmConnectivityConfigName}'
  properties: {
    connectivityTopology: connectivityTopology
    description: 'LabBuilder AVNM - Connectivity Configuration'
    deleteExistingPeering: string(deleteExistingPeering)
    isGlobal: string(isGlobal)
    hubs: [
      {
        resourceId: hubVNETid
        resourceType: 'Microsoft.Network/virtualNetworks'
      }
    ]
    appliesToGroups: [
      {
        networkGroupId: avnmNetworkGroupID
        groupConnectivity: groupConnectivity
        useHubGateway: string(useHubGateway)
        isGlobal: string(isGlobal)
      }
    ]
  }
}

output id string = avnmConnectivityConfig.id
output name string = avnmConnectivityConfig.name
