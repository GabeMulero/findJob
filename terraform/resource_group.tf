# Created by hand as a bootstrap step (see CLAUDE.md "Constraints" — RBAC on
# the CI/CD Service Principal had to be scoped to a resource group that
# already existed before Terraform could run against it). Declared here to be
# imported into state, so it's Terraform-managed going forward rather than a
# permanent hand-created exception like the state storage account is.
resource "azurerm_resource_group" "app" {
  name     = "jobsearch-app"
  location = "southcentralus"
}
