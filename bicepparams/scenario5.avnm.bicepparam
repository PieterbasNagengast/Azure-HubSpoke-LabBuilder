using '../main.bicep'
param deployVnetPeeringMesh = true
param deployVnetPeeringAVNM = true
param adminUsername = ''
param adminPassword = ''
param AddressSpace = '172.16.0.0/16'
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
param deployGatewayInHub = true
param deployFirewallInHub = true
param AzureFirewallTier = 'Standard'
param deployFirewallrules = true
param hubBgp = true
param hubBgpAsn = 65010
param deployOnPrem = true
param onpremRgName = 'LabBuilderValidation-onprem'
param deployBastionInOnPrem = true
param deployVMinOnPrem = true
param deployGatewayinOnPrem = true
param deploySiteToSite = true
param sharedKey = ''
param onpremBgp = true
param onpremBgpAsn = 65020
