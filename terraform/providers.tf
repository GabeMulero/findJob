# Auth is entirely environment-driven, intentionally not hardcoded here, so
# this works unchanged in two different contexts:
#   - Local runs: falls back to the active `az login` session, no env vars needed.
#   - CI (GitHub Actions): ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID,
#     ARM_USE_OIDC=true are set by the workflow, using the OIDC-federated
#     App Registration (see CLAUDE.md "Key identifiers").
provider "azurerm" {
  features {}
}
