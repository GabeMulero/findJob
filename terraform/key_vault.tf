# RBAC authorization, not the legacy access-policy model — consistent with
# everything else in this project. Public network access left enabled,
# deliberately, same reasoning as the Terraform state storage account: I
# need to reach it from my laptop to populate secrets, which has no more
# of a stable IP than GitHub Actions does. RBAC is the actual control here,
# not network — same trade-off, explained once already, applies again.
resource "azurerm_key_vault" "main" {
  name                       = "kv-jobsearch-gm"
  resource_group_name        = azurerm_resource_group.app.name
  location                   = azurerm_resource_group.app.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true

  public_network_access_enabled = true

  # purge_protection_enabled left at default (false) on purpose — this
  # project is still under active construction and may need vaults torn
  # down and recreated. Revisit before anything resembling production use.
}

# Lets me actually manage secret values from my laptop.
resource "azurerm_role_assignment" "me_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
