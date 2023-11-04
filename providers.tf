terraform {
  backend "azurerm" {
    resource_group_name  = "openenv-t74hk"
    storage_account_name = "azuredemosuman"
    container_name       = "tfstate"
    key                  = "terraform-base.tfstate"
  }
}

data "azurerm_client_config" "current" {}