# VNet-integrated via snet-app (delegated back in network.tf, before this
# resource existed - subnet delegation and environment creation are
# independent operations, same pattern as everything else here).
#
# The Container Apps JOB itself (cron schedule, container image, the
# actual compute) is deliberately NOT defined yet - there's no application
# code or image to reference. Creating a Job now with a placeholder image
# would just need to be torn down and rebuilt once real code exists, so
# this phase stops at the environment.
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-jobsearch"
  resource_group_name        = azurerm_resource_group.app.name
  location                   = azurerm_resource_group.app.location
  infrastructure_subnet_id   = azurerm_subnet.app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  logs_destination           = "log-analytics"
}
