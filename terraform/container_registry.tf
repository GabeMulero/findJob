# Basic SKU — cheapest tier, sufficient for a personal project's pull
# volume. No geo-replication, no premium features.
resource "azurerm_container_registry" "main" {
  name                = "acrjobsearchgm"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  sku                 = "Basic"
  admin_enabled       = false
}
