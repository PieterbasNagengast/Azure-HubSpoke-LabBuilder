<h1>Hub or Azure Virtual WAN & Spoke playground - LAB Builder</h1>

[![LabBuilder - Lint, Validation and Deploy Scenarios](https://github.com/PieterbasNagengast/Azure-HubSpoke-LabBuilder/actions/workflows/LabBuilder-ValidateAndDeploy.yml/badge.svg)](https://github.com/PieterbasNagengast/Azure-HubSpoke-LabBuilder/actions/workflows/LabBuilder-ValidateAndDeploy.yml)

## Table of contents

- [Table of contents](#table-of-contents)
- [Deploy to Azure](#deploy-to-azure)
- [Description](#description)
- [Scenario's](#scenarios)
  - [Topology drawing - Hub & Spoke](#topology-drawing---hub--spoke)
  - [Topology drawing - Azure Virtual WAN](#topology-drawing---azure-virtual-wan)
- [Deployment notes](#deployment-notes)
  - [General](#general)
  - [Subnet Ip Address range usage](#subnet-ip-address-range-usage)
  - [Resource Names](#resource-names)
- [Parameters overview](#parameters-overview)
- [Updates](#updates)
  - [September 2022 updates](#september-2022-updates)
  - [July 2022 updates](#july-2022-updates)
  - [June 2022 updates](#june-2022-updates)
  - [May 2022 updates](#may-2022-updates)

## Deploy to Azure

| Description | Template |
|---|---|
| Deploy to Azure Subscription |[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPieterbasNagengast%2FAzure-HubSpoke-LabBuilder%2Fmain%2FARM%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FPieterbasNagengast%2FAzure-HubSpoke-LabBuilder%2Fmain%2FuiDefinition.json)|

> :warning: **Warning:**
> **This deployment is meant for Demo, Test, Learning, Training, Practice or Reproduction purposes ONLY!!**
> **Please don't deploy to production environments!!**

## Description

This Lab Builder is built for testing, training, learning, reproduce and demo purposes which allows for quickly repeatable deployments of a Azure Hub & Spoke topology. All components like: Azure Virtual Machines, Azure Firewalls, Azure Virtual Network Gateways, Azure Bastion Hosts and the number of Spokes are optional making this deployment suitable for every scenario!

Optionaly you can deploy:

- Azure Firewall (Standard or Premium) in the Hub (VNET or vWAN) incl. Route table
- Virtual Machines in Hub VNET and/or Spoke VNET's **
- Bastion Host in Hub VNET and/or Spoke VNET's
- Azure Firewall rule Collection group which enables spoke-to-spoke and internet traffic.
- Simulated 'OnPremises' VNET with optional ***:
  - VPN Gateway
  - Site-2-Site VPN connection to Hub (VNET or vWAN)
  - Bastion Host
  - Virtual Machine

** On deployemnt you can specify the amount of Spoke VNET's to be deployed. VNET peerings will be deployed if both Hub and Spoke(s) are selected for deployement.

*** To simulate OnPrem hybrid connectivity you can optionaly deploy a 'OnPrem' VNET. Optionaly deploy a Bastion Host, Virtual Machine and Virtual Network Gateway in the OnPrem VNET. When a Hub is also deployed with a VPN Gateway you can optionaly deploy a site-to-site VPN connection.

## Scenario's

With LAB Builder you can deploy 4 **main** scenario's.

1. Only deploy **Spoke(s)**
2. Only deploy **VNET Hub** or **Azure Virtual Hub**
3. Deploy **Hub or vWAN Hub and Spoke(s)**
4. Deploy **Hub or vWAN Hub and Spoke(s)** and **OnPrem** simulating Hybrid connectivity

Within these **main** scenario's there are multiple options (but not limited to this):

|Scenrio|What gets deployed|
|-|-|
|**1. Only deploy Spokes**|- Resource Group (rg-Spoke#)<br>- Virtual Network (VNET-Spoke#)<br>- Network Security Group (NSG-Spoke#) linked to 'Default' Subnet<br>- Subnet (Default)<br>- [optional] Subnet (AzureBastionSubnet)<br>- [optional] Subnet (AzureFirewallSubnet)<br>- [optional] Azure Bastion Host (Bastion-Spoke#) incl. Public IP<br>- [optional] Azure Virtual Machine (Windows)<br><br>*Only in combination with Firewall in Hub:*<br>- Route table (RT-Hub) linked to 'Default' Subnet, with default route to Azure Firewall|
|**2. Only deploy Hub or vWAN Hub**|- Resource Group (rg-Hub)<br>- Virtual Network (VNET-Hub)<br>- Network Security Group (NSG-Hub) linked to 'Default' Subnet<br>- Subnet (Default)<br>- [optional] Subnet (AzureBastionSubnet)<br>- [optional] Subnet (AzureFirewallSubnet)<br><br>- [optional] Subnet (GatewaySubnet)<br>- [optional] Azure Bastion Host (Bastion-Hub) incl. Public IP <br>- [optional] Azure Firewall (AzFw) incl. Public IP<br>- [optional] Azure Firewall Policy (AzFwPolicy)<br>- [optional] Azure Firewall Policy rule Collection Group<br>- [optional] Azure Virtual Machine (Windows)<br>- [optional] Virtual Network Gateway<br><br>*Only in combination with Firewall in Hub:*<br>- Route table (RT-Hub) linked to 'Default' Subnet, with default route to Azure Firewall|
|**3. Deploy Hub or vWAN Hub and Spokes**|includes all from scenario 1 and 2, incl:<br>- VNET Peerings|
|**4. Deploy Hub or vWAN Hub and Spokes + OnPrem**|includes all from scenario 1, 2 and 3 incl:<br>- Resource Group (rg-OnPrem)<br>- Virtual Network (VNET-OnPrem)<br>- Network Security Group (NSG-OnPrem) linked to 'Default' Subnet<br>- Subnet (Default)<br>- [optional] Subnet (AzureBastionSubnet)<br>- [optional] Subnet (GatewaySubnet)<br>- [optional] Azure Bastion Host (Bastion-Hub) incl. Public IP<br>- [optional] Azure Virtual Machine (Windows)<br><br>*Only in combination with Hub:*<br>- [optional] Site-to-Site VPN Connection to Hub Gateway

### Topology drawing - Hub & Spoke

![LabBuilderTopology](images/LabBuilder.svg)

### Topology drawing - Azure Virtual WAN

![LabBuilderTopology-vWAN](/images/LabBuilder-vWAN.svg)

## Deployment notes

### General

- VNET Connections will be deployed when vWAN Hub and Spokes are selected
- VNET Peering will be deployed when Hub and Spoke are selected
- ICMPv4 Firewall rule will be enabled on Virtual Machines
- Windows VM image is Windows Server 2022 Datacenter Gen2
- Linux VM image is Ubuntu Server 22.04 LTS Gen2
- Route table incl. Default routes (Private and Public) will be deployed in vWAN Hub if Azure Firewall is selected.  
- Route tables (UDR's) incl. Default route will be deployed if Azure Firewall is selected (0.0.0.0/0 -> Azure Firewall)
- Network Security group will be deplyed to 'default' subnets only
- At deployemt use a /16 subnet. every VNET (Hub and Spoke VNET's) will get a /24 subnet
- Hub VNET will always get the first available /24 subnet. eg. 172.16.0.0/24
- Spoke(s) VNET gets subsequent subnets. eg. 172.16.1.0/24, 172.16.2.0/24 etc.
- OnPrem VNET will always get the latest available /24 subnet. eg. 172.16.255.0/24
- see subnet details:

### Subnet Ip Address range usage

*Spoke VNET's subnets:*

|Subnet Name|Subnet address range|notes|
|-|-|-|
|default|x.x.Y.0/26||
|AzureBastionSubnet|x.x.Y.128/27|Only when Bastion is selected|

*Hub VNET subnets:*

|Subnet Name|Subnet address range|notes|
|-|-|-|
|default|x.x.0.0/26||
|AzureFirewallSubnet|x.x.0.64/26|Only applicable for Hub VNET with Azure Firewall selected|
|AzureBastionSubnet|x.x.0.128/27|Only when Bastion is selected|
|GatewaySubnet|x.x.0.160/27|Only when Gateway is selected|

*Azure virtual WAN Hub subnet:*

|Subnet Name|Subnet address range|notes|
|-|-|-|
|n/a|x.x.0.0/24||

*OnPrem VNET subnets:*

|Subnet Name|Subnet address range|notes|
|-|-|-|
|default|x.x.255.0/26||
|AzureBastionSubnet|x.x.255.128/27|Only when Bastion is selected|
|GatewaySubnet|x.x.255.160/27|Only when Gateway is selected|

### Resource Names

|Type|Name|
|-|-|
|Hub VNET|VNET-Hub|
|Spoke VNET's|VNET-Spoke#|
|Hub Virtual Machine|VM-Hub|
|Spoke Virtual Machines|VM-Spoke#|
|Hub Route Table|RT-Hub|
|Spoke Route tables|RT-Spoke#|
|Hub Bastion Host|Bastion-Hub|
|Spoke Bastion Hosts|Bastion-Spoke#|
|Hub Network Security Group|NSG-Hub|
|Spoke Network Security Groups|NSG-Spoke#|
|Hub Azure Firewall|Firewall-Hub|
|Hub Virtual Network Gateway|Gateway-Hub|
|OnPrem VNET|VNET-OnPrem|
|OnPrem Virtual Machine|VM-OnPrem|
|OnPrem Bastion Host|Bastion-OnPrem|
|OnPrem Network Security Group|NSG-OnPrem|
|OnPrem Virtual Network gateway|Gateway-OnPrem|

## Parameters overview

| Parameter Name | Type | Description | DefaultValue | Possible values |
| :-- | :-- | :-- | :-- | :-- |
| `AddressSpace` | string | IP Address space used for VNETs in deployment. Only enter a /16 subnet. Default = 172.16.0.0/16 | 172.16.0.0/16 |  |
| `adminPassword` | secureString | Admin Password for VM |  |  |
| `adminUsername` | string | Admin username for VM |  |  |
| `amountOfSpokes` | int | Amount of Spoke VNETs you want to deploy. Default = 2 | 2 |  |
| `AzureFirewallTier` | string | Azure Firewall Tier: Standard or Premium | Standard | `Standard` or `Premium` |
| `bastionInHubSKU` | string | Hub Bastion SKU | Basic | `Basic` or `Standard` |
| `bastionInOnPremSKU` | string | OnPrem Bastion SKU | Basic | `Basic` or `Standard` |
| `bastionInSpokeSKU` | string | Spoke Bastion SKU | Basic | `Basic` or `Standard` |
| `deployBastionInHub` | bool | Deploy Bastion Host in Hub VNET | False |  |
| `deployBastionInOnPrem` | bool | Deploy Bastion Host in OnPrem VNET | True |  |
| `deployBastionInSpoke` | bool | Deploy Bastion Host in every Spoke VNET | False |  |
| `deployFirewallInHub` | bool | Deploy Azure Firewall in Hub VNET. includes deployment of custom route tables in Spokes and Hub VNETs | True |  |
| `deployFirewallrules` | bool | Deploy Firewall policy Rule Collection group which allows spoke-to-spoke and internet traffic | True |  |
| `deployGatewayInHub` | bool | Deploy Virtual Network Gateway in Hub VNET | True |  |
| `deployGatewayinOnPrem` | bool | Deploy Virtual Network Gateway in OnPrem VNET | True |  |
| `deployHUB` | bool | Deploy Hub | True |  |
| `deployOnPrem` | bool | Deploy Virtual Network Gateway in OnPrem | True |  |
| `deploySiteToSite` | bool | Deploy Site-to-Site VPN connection between OnPrem and Hub Gateways | True |  |
| `deploySpokes` | bool | Deploy Spoke VNETs | True |  |
| `deployUDRs` | bool | Dploy route tables (UDR's) to VM subnet(s) in Hub and Spokes | True |  |
| `deployVMinHub` | bool | Deploy VM in Hub VNET | False |  |
| `deployVMinOnPrem` | bool | Deploy VM in OnPrem VNET | True |  |
| `deployVMsInSpokes` | bool | Deploy VM in every Spoke VNET | True |  |
| `diagnosticWorkspaceId` | string | Workspace ID of exsisting LogAnalytics Workspace | | |
| `firewallDNSproxy` | bool | Enable Azure Firewall DNS proxy | False | |
| `hubBgp` | bool | Enable BGP on Hub Gateway | True |  |
| `hubBgpAsn` | int | Hub BGP ASN | 65515 |  |
| `hubRgName` | string | Hub resource group pre-fix name | rg-hub |  |
| `hubSubscriptionID` | string | SubscriptionID for HUB deployemnt | [subscription().subscriptionId] |  |
| `hubType` | string | Deploy Hub VNET or Azuere vWAN | VWAN | `VNET` or `VWAN` |
| `location` | string | Azure Region. Defualt = Deployment location | [deployment().location] |  |
| `onpremBgp` | bool | Enable BGP on OnPrem Gateway | True |  |
| `onpremBgpAsn` | int | OnPrem BGP ASN | 65020 |  |
| `onpremRgName` | string | OnPrem Resource Group Name | rg-onprem |  |
| `onPremSubscriptionID` | string | SubscriptionID for OnPrem deployemnt | [subscription().subscriptionId] |  |
| `osTypeHub` | string | Hub Virtual Machine OS type. Windows or Linux. Default = Windows | Windows | `Windows` or `Linux` |
| `osTypeOnPrem` | string | OnPrem Virtual Machine OS type. Windows or Linux. Default = Windows | Windows | `Windows` or `Linux` |
| `osTypeSpoke` | string | Spoke Virtual Machine(s) OS type. Windows or Linux. Default = Windows | Windows | `Windows` or `Linux` |
| `sharedKey` | secureString | Site-to-Site ShareKey |  |  |
| `spokeRgNamePrefix` | string | Spoke resource group prefix name | rg-spoke |  |
| `spokeSubscriptionID` | string | SubscriptionID for Spoke deployemnt | [subscription().subscriptionId] |  |
| `tagsByResource` | object | Tags by resource types |  |  |
| `vmSizeHub` | string | Hub Virtual Machine SKU. Default = Standard_B2s | Standard_B2s |  |
| `vmSizeOnPrem` | string | OnPrem Virtual Machine SKU. Default = Standard_B2s | Standard_B2s |  |
| `vmSizeSpoke` | string | Spoke Virtual Machine SKU. Default = Standard_B2s | Standard_B2s |  |

## Updates

### September 2022 updates

- Enable Azure Firewall DNS proxy and set VNET DNS to Firewall IP address
- Enable Diagnostic settings to log to existing LogAnalytics workspace
- Deploy Microsoft Monitoring agent if existing LogAnalytics is selected

### July 2022 updates

- Multi Subscription deployment. You can now specify different Subscriptions for HUB, Spokes and Onprem deployments
- Virtual machine Sizes. You can now specify different VM Sizes for HUB, Spokes and OnPrem deployments
- Vitual machine Os Types. You can now specify Windows or Linux for HUB, Spokes and OnPrem deployments
- Bastion Host SKU Types. You van noew specify Bastion SKU Basic or Standard for HUB, Spokes and OnPrem deployments
- Updated this ReadMe file

### June 2022 updates

- BGP support for VPN site-to-site (VNET and vWAN)
- Azure Virtual WAN support. Choose between Azure vWAN or VNET for Hub deployments

### May 2022 updates

- Add default Firewall Network & Application rules
- Deploy separate VNET (simulate OnPrem) and deploy VPN gateways including Site-to-Site tunnel
- remove static Resource Group names
- use CIDR notation as Address Space (Instead of first two octets
- Virtual machine OS Type. Windows and Linux support
- Virtual Machine SKU size selection
- Virtual machine boot diagnostics (Managed storage account)
- Virtual machine delete option of Disk and Nic
- Tags support for resources deployed


