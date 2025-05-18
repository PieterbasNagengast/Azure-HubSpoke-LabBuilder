using '../main.bicep'
param deployVnetPeeringMesh = false
param deployVnetPeeringAVNM = true
param adminUsername = ''
param adminPassword = ''
param tagsByResource = {
  'Microsoft.Resources/subscriptions/resourceGroups': {
    LabBuilder: 'validation'
    LabBuilderType: 'avnm'
  }
}
param deploySpokes = true
param amountOfSpokes = 2
param deployVMsInSpokes = false
param deployHUB = true
param hubType = 'VNET'
param deployBastionInHub = false
param deployGatewayInHub = false
param deployFirewallInHub = false
param AzureFirewallTier = 'Standard'
param deployFirewallrules = false
param hubBgp = false
param hubBgpAsn = 65010
param deployOnPrem = true
param deployBastionInOnPrem = false
param deployVMinOnPrem = false
param deployGatewayinOnPrem = false
param deploySiteToSite = false
param sharedKey = ''
param onpremBgp = false
param onpremBgpAsn = 65020
