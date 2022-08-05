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

param diagnosticWorkspaceId string

var EnableICMPv4 = 'netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow'

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

var imagereference = (osType == 'Windows') ? Windows : (osType == 'Linux') ? Linux : {}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
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
  tags: contains(tagsByResource, 'Microsoft.Compute/virtualMachines') ? tagsByResource['Microsoft.Compute/virtualMachines'] : {}
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = if (!empty(diagnosticWorkspaceId)) {
  name: last(split(diagnosticWorkspaceId, '/'))
  scope: az.resourceGroup(split(diagnosticWorkspaceId, '/')[2], split(diagnosticWorkspaceId, '/')[4])
}

resource extension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = if (!empty(diagnosticWorkspaceId)) {
  name: 'MicrosoftMonitoringAgent'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    settings: {
      workspaceId: workspace.id
    }
    protectedSettings: {
      workspaceKey: workspace.listkeys().primarySharedKey
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
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
  tags: contains(tagsByResource, 'Microsoft.Compute/virtualMachines') ? tagsByResource['Microsoft.Compute/virtualMachines'] : {}
}

resource nic_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticWorkspaceId)) {
  name: 'LabBuilder-diagnosticSettings'
  properties: {
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  scope: nic
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
