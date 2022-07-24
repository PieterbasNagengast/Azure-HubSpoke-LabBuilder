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

resource nic_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticWorkspaceId))  {
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
