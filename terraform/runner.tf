locals {
  runner_cloud_config = templatefile(
    "${path.module}/../config/cloud-config-runner.tftpl",
    {
      user_name   = var.runner_runas_user
      scaler_ip   = azurerm_lb.scaler.frontend_ip_configuration[0].private_ip_address
      github_repo = var.github_repo
      labels      = var.runner_labels
    }
  )
}

data "azurerm_image" "runner" {
  name                = var.runner_image_name
  resource_group_name = data.azurerm_resource_group.runner.name
}

resource "azurerm_linux_virtual_machine_scale_set" "runner" {
  name                            = "vmss-runner-${local.location_code}-${var.instance}"
  resource_group_name             = data.azurerm_resource_group.runner.name
  location                        = data.azurerm_resource_group.runner.location
  sku                             = var.runner_sku
  instances                       = 1 # only used for initial bootstrapping. After that scaler takes over.
  admin_username                  = var.runner_runas_user
  admin_password                  = var.admin_pwd
  disable_password_authentication = false
  tags                            = var.tags

  admin_ssh_key {
    username   = var.runner_runas_user
    public_key = "${var.ssh_public_key} ${var.runner_runas_user}"
  }

  source_image_id = data.azurerm_image.runner.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "internal"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = data.azurerm_subnet.runner_subnet.id
    }
  }
  lifecycle {
    ignore_changes = [instances]
  }

  user_data = base64encode(local.runner_cloud_config)
}

resource "azurerm_role_assignment" "scaler_on_runners" {
  scope                = azurerm_linux_virtual_machine_scale_set.runner.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.scaler.principal_id
}

# output "runner_cloud_config" {
#   value = local.runner_cloud_config
# }
