##############################################################
#############     terraform config      ######################
##############################################################
terraform {

  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.11"
    }
  }
}
##############################################################
#############        main config        ######################
##############################################################

resource "azurerm_resource_group" "luftborn" {
  name     = "luftborn-resources"
  location = var.location
}

resource "azurerm_virtual_network" "luftborn_network" {
  name                = "luftborn-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.luftborn.location
  resource_group_name = azurerm_resource_group.luftborn.name
}

resource "azurerm_subnet" "luftborn_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.luftborn.name
  virtual_network_name = azurerm_virtual_network.luftborn_network.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [
    azurerm_virtual_network.luftborn_network
  ]
}

resource "azurerm_public_ip" "luftborn_vm_public_ip" {
  name                = "vm_public_ip"
  resource_group_name = azurerm_resource_group.luftborn.name
  location            = azurerm_resource_group.luftborn.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "luftborn" {
  name                = "luftborn-nic"
  location            = azurerm_resource_group.luftborn.location
  resource_group_name = azurerm_resource_group.luftborn.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.luftborn_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.luftborn_vm_public_ip.id
  }
  depends_on = [
    azurerm_virtual_network.luftborn_network,
    azurerm_public_ip.luftborn_vm_public_ip
  ]
}

resource "tls_private_key" "luftborn_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "linux_key" {
  filename = "luftborn_key.pem"
  content  = tls_private_key.luftborn_key.private_key_pem
}
resource "azurerm_linux_virtual_machine" "luftborn" {
  name                = "luftborn-machine"
  resource_group_name = azurerm_resource_group.luftborn.name
  location            = azurerm_resource_group.luftborn.location
  size                = "Standard_F2"
  admin_username      = var.USER
  network_interface_ids = [
    azurerm_network_interface.luftborn.id,
  ]

  admin_ssh_key {
    username   = var.USER
    public_key = tls_private_key.luftborn_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.luftborn,
    tls_private_key.luftborn_key
  ]
}

resource "null_resource" "remote_executer" {

  provisioner "file" {
    source      = "nginx.sh"
    destination = "/tmp/nginx.sh"

  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nginx.sh",
      "sudo /tmp.nginx.sh"
    ]
  }
  connection {
    user        = "var.USER"
    private_key = tls_private_key.luftborn_key.private_key_pem
    host        = azurerm_public_ip.luftborn_vm_public_ip
  }
}
