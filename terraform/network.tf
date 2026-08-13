# Two subnets, matching docs/architecture.md's snet-app / snet-data split.
# snet-app is delegated to Container Apps environments now, even though the
# environment resource itself isn't created until the next phase — this is
# subnet config, not the environment, so there's no cost or coupling in
# setting it up ahead of time.

resource "azurerm_virtual_network" "main" {
  name                = "vnet-jobsearch"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/23"]

  delegation {
    name = "container-apps-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  # Azure auto-provisioned this alongside the Postgres server for its
  # backup mechanism's network path to Microsoft-managed storage. Declared
  # explicitly so Terraform stops trying to remove it as drift.
  service_endpoint {
    service = "Microsoft.Storage"
  }

  delegation {
    name = "postgres-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
