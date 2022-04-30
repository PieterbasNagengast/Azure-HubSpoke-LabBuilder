# Hub & Spoke playground - LAB Builder

## Index

- [Hub & Spoke playground - LAB Builder](#hub--spoke-playground---lab-builder)
  - [Index](#index)
  - [Deploy to Azure](#deploy-to-azure)
  - [Introduction](#introduction)
  - [Description](#description)
    - [LABbuilder scenario's](#labbuilder-scenarios)
  - [Topology drawing](#topology-drawing)
  - [Deployment Steps](#deployment-steps)
  - [Appendix](#appendix)
    - [Parameters](#parameters)
    - [~~Backlog~~... whishlist items](#backlog-whishlist-items)

## Deploy to Azure

| Description | Template |
|---|---|
| Deploy to Azure Subscription |[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPieterbasNagengast%2FAzure-HubSpoke-LabBuilder%2Fmain%2FARM%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FPieterbasNagengast%2FAzure-HubSpoke-LabBuilder%2Fmain%2FuiDefinition.json)|

> :warning: **Warning:**
> **This deployment is ment for Testing, Training, Practice or Reproduction purposes ONLY!!**
> **Please don't deploy to production environments!!**

## Introduction

In my daily work I've created numourous times a (semi-)manual Hub & Spoke topology for Testing, (Self)Training, Demo or Reproduction purposes. I've always done this in multiple ways, like: PowerShell scripts, Azure CLI, ARM or Azure Potal GUI.....whatever was the best fit. But bottom line: Wathever option is fine by me as long as it has the least amount of effort to build it.

With that in mind I've created a "Hub & Spoke playground Lab builder" so you'll be able to deploy Hub & Spoke scenario's in notime :) It takes approx. 20min to deploy a 'full option Hub & Spoke' deployment with 2 Spoke VNET's.

## Description

With this 'Hub & Spoke playground - LAB Builder' you'll be able to deploy Hub & Spoke topologies in various ways.

Optionaly you can deploy Azure Firewall (Standard or Premium) in Hub VNET incl. Route table, deploy Virtual Machine in Hub VNET and/or Spoke VNET's and deploy Bastion Host in Hub VNET and/or Spoke VNET's. On deployemnt you can specify the amount of Spoke VNET's to be deployed. VNET peerings will be deployed if both Hub and Spoke(s) are selected for deployement.

### LABbuilder scenario's

With LABbuilder you can deploy three **main** scenario's.

1. Only deploy **Spoke(s)**
2. Only deploy **Hub**
3. Deploy **Hub and Spoke(s)**

Within these three **main** scenario's there are multiple options:

|Scenrio|What gets deployed|
|-|-|
|**1. Only deploy Spokes**|- Resource Group (rg-Spoke#)<br>- Virtual Network (VNET-Spoke#)<br>- Network Security Group (NSG-Spoke#) linked to 'Default' Subnet<br>- Subnet (Default)<br>- [optional] Subnet (AzureBastionSubnet)<br>- [optional] Subnet (AzureFirewallSubnet)<br>- [optional] Azure Bastion Host (Bastion-Spoke#) incl. Public IP<br>- [optional] Azure Virtual Machine (Windows)<br><br>*Only in combination with Firewall in Hub:*<br>- Route table (RT-Hub) linked to 'Default' Subnet, with default route to Azure Firewall|
|**2. Only deploy Hub**|- Resource Group (rg-Hub)<br>- Virtual Network (VNET-Hub)<br>- Network Security Group (NSG-Hub) linked to 'Default' Subnet<br>- Subnet (Default)<br>- [optional] Subnet (AzureBastionSubnet)<br>- [optional] Subnet (AzureFirewallSubnet)<br>- [optional] Azure Bastion Host (Bastion-Hub) incl. Public IP <br>- [optional] Azure Firewall (AzFw) incl. Public IP<br>- [optional] Azure Firewall Policy (AzFwPolicy)<br>- [optional] Azure Virtual Machine (Windows)<br><br>*Only in combination with Firewall in Hub:*<br>- Route table (RT-Hub) linked to 'Default' Subnet, with default route to Azure Firewall|
|**3. Deploy Hub and Spokes**|includes all from scenario 1 and 2, incl:<br>- VNET Peerings|

## Topology drawing

![LabBuilderTopology](images/LabBuilder.svg)

## Deployment Steps

|Step|Screenshot|
|-|-|
|Select Subscription and Region<br>Enter the first two octets of a **/16** subnet<br>example: **172.16.**<br><br>*Note: Hub VNET will always get the first available /24 subnet, first spoke the second subnet etc.<br>like:<br>172.16.0.0/24 = Hub VNET<br>172.16.1.0/24 = Spoke1<br>172.16.2.0/24 = Spoke2<br>etc.*|![Step1](images/DeployToAzure-Step1.png)|
|Deploy Hub<br>Optional enable:<br>- Azure Bastion<br>- Virtual Machine<br>- Azure Firewall Standard or Premium|![Step2](images/DeployToAzure-Step2.png)|
|Deploy Spokes<br>Enter amount of Spokes to deploy (Max 25)<br>Optional enable:<br>- Virtual Machine<br>- Azure Bastion<br><br> *Note: VM and Azure Bastion will be deployed in every Spoke*|![Step3](images/DeployToAzure-Step3.png)|
|Enter Local Admin credentials If Virtual Machine is selected for Hub and/or Spoke|![Step4](images/DeployToAzure-Step4.png)|
|Validate and Deploy|![Step5](images/DeployToAzure-Step5.png)|

## Appendix

### Parameters

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

### ~~Backlog~~... whishlist items

- Choose between Azure vWAN and Hub & Spoke
- Add default Firewall Network & Application rules
- Deploy separate VNET (simulate OnPrem) and deploy VPN gateways including Site-to-Site tunnel
- etc...