param location string
param vmName string
param adminUsername string
@secure()
param adminPassword string
param subnetID string
param vmSize string
param storageType string = 'StandardSSD_LRS'
param osType string = 'Windows'
param tagsByResource object = {}
param dcrID string

param diagnosticWorkspaceId string

var EnableICMPv4 = 'netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow'

var AmaExtensionName = osType == 'Windows' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
var AmaExtensionType = osType == 'Windows' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
var AmaExtensionVersion = '1.0'

var DaExtensionName = 'DependencyAgentWindows'
var DaExtensionType = 'DependencyAgentWindows'
var DaExtensionVersion = '9.5'

var Windows = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter-g2'
  version: 'latest'
}

var Linux = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

var imagereference = osType == 'Windows' ? Windows : osType == 'Linux' ? Linux : {}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imagereference
      osDisk: {
        createOption: 'FromImage'
        name: '${vmName}-osDisk'
        managedDisk: {
          storageAccountType: storageType
        }
        osType: osType
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: tagsByResource[?'Microsoft.Compute/virtualMachines'] ?? {}
}

resource amaextension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (!empty(diagnosticWorkspaceId)) {
  name: AmaExtensionName
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: AmaExtensionType
    typeHandlerVersion: AmaExtensionVersion
    autoUpgradeMinorVersion: true
  }
}

resource daextension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (!empty(diagnosticWorkspaceId) && osType == 'Windows') {
  name: DaExtensionName
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: DaExtensionType
    typeHandlerVersion: DaExtensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      enableAMA: true
    }
  }
}

resource dcrassociation 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = if (!empty(diagnosticWorkspaceId)) {
  name: 'VMInsights-Dcr-Association'
  scope: vm
  properties: {
    dataCollectionRuleId: dcrID
    description: 'Association of data collection rule for VM Insights.'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
        }
      }
    ]
  }
  tags: tagsByResource[?'Microsoft.Compute/virtualMachines'] ?? {}
}

module run 'runcommand.bicep' = if (osType == 'Windows') {
  name: '${vmName}-runCommand'
  params: {
    location: location
    runCommand: EnableICMPv4
    vmName: vm.name
  }
}

output vmResourceID string = vm.id
