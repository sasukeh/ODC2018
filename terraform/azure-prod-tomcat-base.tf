
#-------------------------------------------------------
# Stetment of Resource Group
#-------------------------------------------------------
resource "azurerm_resource_group" "prod-tomcat" {
  name     = "001-prod-tomcat"
  location = "Japan East"
}
resource "azurerm_managed_disk" "prod-tomcat" {
  name                 = "prod-tomcat-datadisk"
  location             = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name  = "${azurerm_resource_group.prod-tomcat.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}
#-------------------------------------------------------
# Creating Networking 
#-------------------------------------------------------
resource "azurerm_virtual_network" "prod-tomcat" {
  name                = "prod-tomcat-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.prod-tomcat.name}"
}

resource "azurerm_subnet" "prod-tomcat" {
  name                 = "prod-tomcat-subnet"
  resource_group_name  = "${azurerm_resource_group.prod-tomcat.name}"
  virtual_network_name = "${azurerm_virtual_network.prod-tomcat.name}"
  address_prefix       = "10.0.2.0/24"
}


resource "azurerm_public_ip" "prod-tomcat" {
  name                         = "prodTomcatPublicIP"
  location                     = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name          = "${azurerm_resource_group.prod-tomcat.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "prod-tomcat" {
  name                = "prod-tomcat-service-nic"
  location            = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.prod-tomcat.name}"

  ip_configuration {
    name                          = "ProdTomcatServicePIPConfiguration"
    subnet_id                     = "${azurerm_subnet.prod-tomcat.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.prod-tomcat.id}"
  }
}


#-------------------------------------------------------
# Creating Compute
#-------------------------------------------------------

resource "azurerm_availability_set" "prod-tomcat-as" {
  name                         = "prod-tomcat-as"
  location                     = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name          = "${azurerm_resource_group.prod-tomcat.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "prod-tomcat" {
  name                  = "prod-tomcat-vm"
  location              = "${azurerm_resource_group.prod-tomcat.location}"
  availability_set_id   = "${azurerm_availability_set.prod-tomcat-as.id}"
  resource_group_name   = "${azurerm_resource_group.prod-tomcat.name}"
  network_interface_ids = ["${azurerm_network_interface.prod-tomcat.id}"]
  vm_size               = "Standard_DS1_v2"

  identity = {
    type = "SystemAssigned"
  }

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "prod-tomcat-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "prod-tomcat-datadisk-001"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.prod-tomcat.name}"
    managed_disk_id = "${azurerm_managed_disk.prod-tomcat.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "1023"
  }

    os_profile {
        computer_name  = "prod-tomcat"
        admin_username = "kyoheim"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/kyoheim/.ssh/authorized_keys"
	    key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCeOVMQjTiGRdPQ3s5aBEZc6NSSsC/9Q1g/7X266bJgzOMAOlqdiCwj7Mv4baN2eaZO9DDHrLVS8WQIvHti2W6SgU4cCCiQLI8FNkFwgeEtIj8Ul8IcreMpsNuQsZbs0jItxPROe6mOWpp5n2jmlFS6UgC8uBrMwx80N0w5LaZhIJb8O2kAZZAa31jXyLvX12JHMbleCx2AQ6a0MQBnL3eBrUWf2JNY9OwcuX2PDD/1aA/lmHfrasdtkMEKPaRCrXBog/GzvhwhTtxTosNVW6RYObfoHjmk5BZwACszlMrHk1BkHt6KGaERdP2r5mwiBVvsIfzyNOdm53xS9ExQInCR" 
        }
    }
  tags {
    environment = "staging"
  }
}
