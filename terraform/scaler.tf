data "azurerm_subnet" "runner_subnet" {
  name                 = var.subnet
  virtual_network_name = var.vnet
  resource_group_name  = var.vnet_resource_group
}

data "azurerm_resource_group" "runner" {
  name = var.runner_resource_group
}

data "azurerm_subscription" "subscription" {
}

data "azurerm_client_config" "current" {
}

locals {
  location_code = var.location == "francecentral" ? "weu" : "frc"
  app_requirements = indent(6, file("${path.module}/../scaler/requirements.txt"))
  app_code         = indent(6, file("${path.module}/../scaler/scaler.py"))
  scaler_cloud_config = templatefile(
    "${path.module}/../config/cloud-config-scaler.tftpl",
    {
      app_requirements                 = local.app_requirements
      app_code                         = local.app_code
      log_level                        = var.scaler_log_level
      run_as_user                      = var.runner_runas_user
      keyvault_url                     = azurerm_key_vault.scaler.vault_uri
      github_repo                      = var.github_repo
      subscription_id                  = data.azurerm_subscription.subscription.subscription_id
      resource_group                   = data.azurerm_resource_group.runner.name
      runner_vmss_name                 = azurerm_linux_virtual_machine_scale_set.runner.name
      storage_account_name             = azurerm_storage_account.queue.name
      min_runners                      = var.min_runners
      max_runners                      = var.max_runners
      target_available_runners_percent = var.target_available_runners_percent
    }
  )
}

resource "azurerm_user_assigned_identity" "scaler" {
  resource_group_name = data.azurerm_resource_group.runner.name
  location            = data.azurerm_resource_group.runner.location
  name                = "scaler-id-${local.location_code}-${var.instance}"
  tags                = var.tags
}

resource "azurerm_linux_virtual_machine_scale_set" "scaler" {
  name                            = "vmss-scaler-${local.location_code}-${var.instance}"
  resource_group_name             = data.azurerm_resource_group.runner.name
  location                        = data.azurerm_resource_group.runner.location
  sku                             = var.scaler_sku
  instances                       = var.scaler_instances
  admin_username                  = var.scaler_admin_user
  admin_password                  = var.admin_pwd
  disable_password_authentication = false
  tags                            = var.tags

  admin_ssh_key {
    username   = var.scaler_admin_user
    public_key = "${var.ssh_public_key} ${var.scaler_admin_user}"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "internal"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = data.azurerm_subnet.runner_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.scaler.id]
    }
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.scaler.id]
  }

  user_data = base64encode(local.scaler_cloud_config)
}

resource "azurerm_role_assignment" "scaler_on_subnet" {
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.scaler.principal_id
  scope                = data.azurerm_subnet.runner_subnet.id
}

resource "azurerm_role_assignment" "scaler_on_rg" {
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.scaler.principal_id
  scope                = data.azurerm_resource_group.runner.id
}


resource "azurerm_lb" "scaler" {
  name                = "lb-scaler-${local.location_code}-${var.instance}"
  location            = data.azurerm_resource_group.runner.location
  resource_group_name = data.azurerm_resource_group.runner.name
  tags                = var.tags

  frontend_ip_configuration {
    name               = "scaler-ip"
    subnet_id          = data.azurerm_subnet.runner_subnet.id
    private_ip_address = cidrhost(data.azurerm_subnet.runner_subnet.address_prefix, 4)
  }
}

resource "azurerm_lb_backend_address_pool" "scaler" {
  name            = "backendpool"
  loadbalancer_id = azurerm_lb.scaler.id
}

resource "azurerm_lb_probe" "scaler" {
  loadbalancer_id = azurerm_lb.scaler.id
  name            = "http-health-probe"
  protocol        = "Http"
  request_path    = "/health"
  port            = var.scaler_port
}

resource "azurerm_lb_rule" "scaler" {
  loadbalancer_id                = azurerm_lb.scaler.id
  name                           = "Http"
  protocol                       = "Tcp"
  frontend_port                  = var.scaler_port
  backend_port                   = var.scaler_port
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.scaler.id]
  frontend_ip_configuration_name = "scaler-ip"
  probe_id                       = azurerm_lb_probe.scaler.id
}

# output "scaler_cloud_config" {
#   value = local.scaler_cloud_config
# }
