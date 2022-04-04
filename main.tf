terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.2"
    }
  }

  backend "azurerm" {
    storage_account_name = "kmxterraformbackend"
    container_name       = "k8s-terraform"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
    name = "Kubernetes"
    location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
    name = "k8s-vnet"
    address_space = ["10.0.0.0/16"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    name = "AzureFirewallSubnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pubip" {
    name = "k8s-ip"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
    sku = "Standard"
}

resource "azurerm_firewall" "firewall" {
    name = "k8s-firewall"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku_name = "AZFW_VNet"
    sku_tier = "Standard"

    ip_configuration {
        name = "configuration"
        subnet_id = azurerm_subnet.subnet.id
        public_ip_address_id = azurerm_public_ip.pubip.id
    }
}