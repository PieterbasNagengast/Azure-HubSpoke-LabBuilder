param avnmName string
param avnmGroupName string
param spokeVNETids array

resource avnmNetworkGroup 'Microsoft.Network/networkManagers/networkGroups@2022-11-01' = {
  name: '${avnmName}/${avnmGroupName}'
  properties: {
    description: 'LabBuilder AVNM - Network Group'
  }
}

resource avnmNetworkGroupMemeber 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-11-01' = [for (vnetid, i) in spokeVNETids: {
  name: 'avnmNetworkGroupMemeber${i}'
  parent: avnmNetworkGroup
  properties: {
    resourceId: vnetid
  }
}]

output id string = avnmNetworkGroup.id
