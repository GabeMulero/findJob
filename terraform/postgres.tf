# Postgres Flexible Server, private-only via VNet integration (delegated
# subnet + private DNS zone — Flexible Server's own mechanism, not the
# generic azurerm_private_endpoint resource used elsewhere in Azure).
#
# No password, anywhere. active_directory_auth_enabled = true and
# password_auth_enabled = false mean the server only accepts Entra ID
# tokens — consistent with every other credential in this project.

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.app.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                = "postgres-vnet-link"
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  virtual_network_id  = azurerm_virtual_network.main.id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-jobsearch"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  version             = "16"

  delegated_subnet_id           = azurerm_subnet.data.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  # Azure auto-assigned this zone at creation; pinned explicitly to match
  # reality rather than have Terraform null it out on every plan.
  zone = "2"

  # Burstable, smallest SKU — cheapest tier, correct trade-off for a
  # personal job-application tracker with no sustained load.
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Bootstrap AAD admin — needed to exist before anything else can be granted
# access. The application's own runtime identity gets added as a non-admin
# Postgres role separately, once that identity exists (next phase);
# Terraform/ARM has no native resource for that step — it's a SQL-level
# grant, run once against the server itself.
#
# principal_name is truncated to 63 chars, not a typo. This API silently
# truncates on ingest rather than validating length up front — the full UPN
# (longer than 63 chars due to the #EXT# guest-account encoding) caused a
# generic, unhelpful "InternalServerError" via Terraform on two consecutive
# real attempts. Diagnosed by running the equivalent `az` CLI command
# directly, which succeeded and revealed the actual stored (truncated)
# value. This field is cosmetic display text only — object_id/tenant_id are
# what actually govern authentication, so the truncation has no functional
# effect. Resource was created via CLI and imported into state; matching
# the config to reality here so Terraform doesn't try to "fix" it back to
# the string that breaks.
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "me" {
  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = azurerm_resource_group.app.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  principal_name      = "gabrielalexandermulero_gmail.com#EXT#@gabrielalexandermulerogm2"
  principal_type      = "User"
}
