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
param spokeRgNamePrefix = 'LabBuilderValidation-spoke'
param amountOfSpokes = 2
param deployVMsInSpokes = true
param deployHUB = true
param hubType = 'VNET'
param hubRgName = 'LabBuilderValidation-hub'
param deployBastionInHub = true
param deployGatewayInHub = false
param deployFirewallInHub = true
param AzureFirewallTier = 'Standard'
param deployFirewallrules = true
param hubBgp = false
param hubBgpAsn = 65010
param deployOnPrem = true
param onpremRgName = 'LabBuilderValidation-onprem'
param deployBastionInOnPrem = true
param deployVMinOnPrem = true
param deployGatewayinOnPrem = false
param deploySiteToSite = false
param sharedKey = ''
param onpremBgp = false
param onpremBgpAsn = 65020
