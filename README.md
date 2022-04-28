# LABbuilder

## Introduction

In my daily work I've created, numourous times, a (semi-)manual Hub & Spoke topologie for Testing, (Self)Training, Demo or Reproduction purposes.
I've always done this via multiple ways, like: PowerShell scripts, Azure CLI, ARM or Azure Potal GUI..... but bottom line: Wathever option is fine by me as long as it is the least amount of effort.

## Description

With this 'LAB Builder' you'll be able to deploy a Hub&Spoke topology in Azure in notime!

.. warning:
>[!WARNING]
>csdcds

> :warning: **This deployment is for Testing, Demo-ing, (self)Training, Practice or Reproduction purposes ONLY!!**
> :warning: Don't deploy to production environments!!

## LABbuilder scenario's

With LABbuilder you can deploy three **main** scenario's.

**1. Only deploy Spokes**
**2. Only deploy Hub**
**3. Deploy Hub and Spokes**

*Note: Within these three main scenario's you can have multiple options, set by parameters.*

|Scenrio|What gets deployed|
|-|-|
|**1. Only deploy Spokes**|- Resource Group (rg-Spoke#)<br>- Virtual Network (VNET-Spoke#)<br>- Network Security Group (NSG-Spoke#) linked to 'Default' Subnet<br>- Subnet (Default)<br>- [optional] Subnet (AzureBastionSubnet)<br>- [optional] Subnet (AzureFirewallSubnet)<br>- [optional] Azure Bastion Host (Bastion-Spoke#) incl. Public IP<br>- [optional] Azure Virtual Machine (Windows)<br><br>*Only in combination with Firewall in Hub:*<br>- Route table (RT-Hub) linked to 'Default' Subnet, with default route to Azure Firewall|
|**2. Only deploy Hub**|- Resource Group (rg-Hub)<br>- Virtual Network (VNET-Hub)<br>- Network Security Group (NSG-Hub) linked to 'Default' Subnet<br>- Subnet (Default)<br>- [optional] Subnet (AzureBastionSubnet)<br>- [optional] Subnet (AzureFirewallSubnet)<br>- [optional] Azure Bastion Host (Bastion-Hub) incl. Public IP <br>- [optional] Azure Firewall (AzFw) incl. Public IP<br>- [optional] Azure Firewall Policy (AzFwPolicy)<br>- [optional] Azure Virtual Machine (Windows)<br><br>*Only in combination with Firewall in Hub:*<br>- Route table (RT-Hub) linked to 'Default' Subnet, with default route to Azure Firewall|
|**3. Deploy Hub and Spokes**|includes all from scenario 1 and 2, incl:<br>- VNET Peerings|

## Parameters

|Parameter name|type|default value|notes|
|-|-|-|-|
|adminUsername|string|n/a|Admin username for VM|
|adminPassword|secure string|n/a|Admin password for VM|
|startAddressSpace|string|172.16.|IP Address space used for VNETs in deployment.<br>Only enter the two first octets of a /16 subnet. Default = 172.16.|
|location|string|deployment().location|Azure Region. Defualt = Deployment location|
|deploySpokes|bool|true|Deploy Spoke VNETs|
|amountOfSpokes|int|2|Amount of Spoke VNETs you want to deploy. Default = 2|
|deployVMsInSpokes|bool|true|Deploy VM in every Spoke VNET|
|deployBastionInSpoke|bool|false|Deploy Bastion Host in every Spoke VNET|
|DeployHUB|bool|true|bool|Deploy Hub VNET|
|deployBastionInHub|bool|true|Deploy Bastion Host in Hub VNET|
|deployVMinHub|bool|true|Deploy VM in Hub VNET|
|deployFirewallInHub|bool|true|Deploy Azure Firewall in Hub VNET.<br>Includes deployment of custom route tables in Spokes and Hub VNETs|
|AzureFirewallTier|string|Standard|Azure Firewall Tier: Standard or Premium|

## Deploy to Azure

| Description | Template |
|---|---|
| Deploy to Azure Subscription |[![Deploy To Azure](https://docs.microsoft.com/en-us/azure/templates/media/deploy-to-azure.svg)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPieterbasNagengast%2FLABbuilder%2Fmain%2FuiDefinition.json%3Ftoken%3DGHSAT0AAAAAABRYUUI6IJ4UX3MCQGKZZMLOYTLB5ZQ/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FPieterbasNagengast%2FLABbuilder%2Fmain%2FARM%2Fmain.json%3Ftoken%3DGHSAT0AAAAAABRYUUI7ZNUVZZWRUSCDPF4QYTLCCRQ)|

> :exclamation:
> **This deployment is for Testing, Demo-ing, (self)Training, Practice or Reproduction purposes ONLY!!**
> **Don't deploy to production environments!!**

## ~~Backlog~~... whishlist items

- Choose between Azure vWAN and Hub & Spoke
- Add default Firewall Network & Application rules
- Deploy separate VNET (simulate OnPrem) and deploy VPN gateways including Site-to-Site tunnel
- etc...