# Remote state lives in the bootstrap storage account created by hand (see
# docs/architecture.md §1 and CLAUDE.md "Key identifiers"). That account is
# deliberately NOT managed by this Terraform config — it can't be, since this
# config depends on it existing to run at all.
#
# use_azuread_auth = true: the storage account has shared-key access disabled.
# Auth is Entra ID only. use_oidc is intentionally omitted here — it's set via
# the ARM_USE_OIDC environment variable instead, so this same config works
# unchanged locally (falls back to the active `az login` session) and in CI
# (picks up OIDC via GitHub Actions' federated token).
terraform {
  backend "azurerm" {
    resource_group_name  = "jobsearch-infrastructure"
    storage_account_name = "jobsearchstorageaccount"
    container_name        = "terraform"
    key                   = "findjob.tfstate"
    use_azuread_auth      = true
  }
}
