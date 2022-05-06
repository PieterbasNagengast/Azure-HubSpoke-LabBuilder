param location string
param vmName string
param adminUsername string
@secure()
param adminPassword string
param subnetID string
param vmSize string
param storageType string = 'StandardSSD_LRS'
@allowed([
  '2022-datacenter-g2'
])
param OSVersion string = '2022-datacenter-g2'
param tagsByResource object = {}

var EnableICMPv4 = 'netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow'

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
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageType
        }
        osType: 'Windows'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    hardwareProfile: {
      vmSize: vmSize
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

module run 'runcommand.bicep' = {
  name: '${vmName}-runCommand'
  params: {
    location: location
    runCommand: EnableICMPv4
    vmName: vm.name
  }
}
