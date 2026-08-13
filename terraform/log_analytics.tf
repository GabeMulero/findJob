resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-jobsearch"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
