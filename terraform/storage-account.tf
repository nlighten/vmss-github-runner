# todo: add private endpoints
resource "azurerm_storage_account" "image" {
  name                     = "stghrimages${local.location_code}"
  resource_group_name      = data.azurerm_resource_group.runner.name
  location                 = data.azurerm_resource_group.runner.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_account" "queue" {
  name                     = "stghrqueue${local.location_code}"
  resource_group_name      = data.azurerm_resource_group.runner.name
  location                 = data.azurerm_resource_group.runner.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_queue" "scaler" {
  name                 = azurerm_linux_virtual_machine_scale_set.runner.name
  storage_account_name = azurerm_storage_account.queue.name
}


resource "azurerm_role_assignment" "scaler_on_queue" {
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.scaler.principal_id
  scope                = azurerm_storage_account.queue.id
}
