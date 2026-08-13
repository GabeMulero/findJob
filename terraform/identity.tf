# The RUNTIME identity — separate from the App Registration used for
# CI/CD. This is what the Container Apps Job itself will authenticate as
# once it exists: pull its image from ACR, read secrets from Key Vault,
# and (in a later step, once it exists) connect to Postgres via Entra ID.
resource "azurerm_user_assigned_identity" "runtime" {
  name                = "id-jobsearch-runtime"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
}

resource "azurerm_role_assignment" "runtime_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.runtime.principal_id
}

# Read-only on secrets - the running agent reads config/credentials, it
# never manages the vault itself.
resource "azurerm_role_assignment" "runtime_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.runtime.principal_id
}
