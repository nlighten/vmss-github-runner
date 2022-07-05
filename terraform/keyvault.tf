# todo: add private endpoint
resource "azurerm_key_vault" "scaler" {
  name                        = "kv-ghscaler-${local.location_code}-${var.instance}"
  location                    = data.azurerm_resource_group.runner.location
  resource_group_name         = data.azurerm_resource_group.runner.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags
}

resource "azurerm_key_vault_access_policy" "scaler" {
  key_vault_id = azurerm_key_vault.scaler.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.scaler.principal_id

  secret_permissions = [
    "Get",
  ]
}
