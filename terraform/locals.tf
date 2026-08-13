locals {
  # My own (human) Entra ID object ID — deliberately hardcoded, not derived
  # from data.azurerm_client_config.current. That data source reflects
  # WHOEVER IS CURRENTLY AUTHENTICATED - me when run locally, the CI/CD
  # Service Principal when run via the pipeline. Using it for "grant me
  # access" resources is a real bug, not a style choice: it silently
  # regrants those resources to the CI identity every time CI applies this
  # config, instead of to me. Found via a live state diff where exactly
  # this had already happened. tenant_id references to the same data
  # source elsewhere are fine - tenant doesn't vary by caller, only
  # identity does.
  my_object_id = "cfdad11c-d594-44de-993e-20b5ffc95edb"
}
