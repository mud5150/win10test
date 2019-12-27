provider "azurerm" {}

data "azurerm_resource_group" "rg" {
  name = "${var.resource_group}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project}-vnet"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "data" {
  name                 = "data"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.0.0/24"
}

resource "azurerm_subnet" "bastion" {
  name                 = "bastion"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.1.0/24"
}



resource "azurerm_network_interface" "client-nic" {
  name                = "${var.project}-nic"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${var.project}"
    subnet_id                     = "${azurerm_subnet.data.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_string" "password" {
  length      = 10
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}


resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.project}-client"
  location              = "${data.azurerm_resource_group.rg.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  vm_size               = "Standard_D2"
  network_interface_ids = ["${azurerm_network_interface.client-nic.id}"]

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h2-pro"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  os_profile {
    computer_name  = "${var.project}-client"
    admin_username = "${var.project}"
    admin_password = "${random_string.password.result}"
  }
}

resource "azurerm_public_ip" "bastion" {
  name                = "${var.project}-bastion-ip"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  sku                 = "Standard"
  allocation_method   = "Static"
  location            = "${data.azurerm_resource_group.rg.location}"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.project}-bastion"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                 = "bastion"
    subnet_id            = "${azurerm_subnet.bastion.id}"
    public_ip_address_id = "${azurerm_public_ip.bastion.id}"
  }
}
