terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.2"
    }
  }

  backend "azurerm" {
    storage_account_name = "kmxterraform"
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

resource "azurerm_subnet" "fw-subnet" {
    name = "AzureFirewallSubnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet" {
    name = "k8s-subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name = "k8s-nsg"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
        subnet_id = azurerm_subnet.fw-subnet.id
        public_ip_address_id = azurerm_public_ip.pubip.id
    }
}

# Compute VMs
resource "azurerm_network_interface" "controller-nic" {
  count = 3
  name = "k8s-controller-nic-${count.index}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.0.1${count.index}"
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  count = 3
  network_interface_id = "${element(azurerm_network_interface.controller-nic.*.id, count.index)}"
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "controllers" {
  count = 3
  name = "controller-${count.index}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size = "Standard_D2s_v3"
  admin_username = "adminuser"
  network_interface_ids = [
    "${element(azurerm_network_interface.controller-nic.*.id, count.index)}"
  ]

  admin_ssh_key {
    username = "adminuser"
    public_key = file("C:/Users/260725/.ssh/id_rsa.pub")
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-focal"
    sku = "20_04-lts"
    version = "latest"
  }
}

# Worker VMs
resource "azurerm_network_interface" "worker-nic" {
  count = 3
  name = "k8s-worker-nic-${count.index}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.0.2${count.index}"
  }
}

resource "azurerm_network_interface_security_group_association" "worker-nic-nsg" {
  count = 3
  network_interface_id = "${element(azurerm_network_interface.worker-nic.*.id, count.index)}"
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "workers" {
  count = 3
  name = "worker-${count.index}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size = "Standard_D2s_v3"
  admin_username = "adminuser"
  network_interface_ids = [
    "${element(azurerm_network_interface.worker-nic.*.id, count.index)}"
  ]

  admin_ssh_key {
    username = "adminuser"
    public_key = file("C:/Users/260725/.ssh/id_rsa.pub")
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-focal"
    sku = "20_04-lts"
    version = "latest"
  }
}

resource "azurerm_firewall_nat_rule_collection" "ssh-nat-rule" {
  name = "external-ssh"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority = 100
  action = "Dnat"

  dynamic "rule" {
    for_each = range(0, length(azurerm_network_interface.controller-nic))
    content {
      name = "controller-${rule.value}"
      protocols = ["TCP"]
      source_addresses = ["*"]
      destination_addresses = [
        azurerm_public_ip.pubip.ip_address
      ]
      destination_ports = [
        "2201${rule.value}"
      ]
      translated_port = 22
      translated_address = "${element(azurerm_network_interface.controller-nic.*.private_ip_address, rule.value)}"
    }
    
  }

  dynamic "rule" {
    for_each = range(0, length(azurerm_network_interface.worker-nic))
    content {
      name = "worker-${rule.value}"
      protocols = ["TCP"]
      source_addresses = ["*"]
      destination_addresses = [
        azurerm_public_ip.pubip.ip_address
      ]
      destination_ports = [
        "2202${rule.value}"
      ]
      translated_port = 22
      translated_address = "${element(azurerm_network_interface.worker-nic.*.private_ip_address, rule.value)}"
    }
  }
}