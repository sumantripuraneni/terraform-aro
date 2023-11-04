terraform {
  backend "azurerm" {
    resource_group_name  = "openenv-9rpv6"
    storage_account_name = "azuredemosuman1"
    container_name       = "tfstate"
    key                  = "terraform-base.tfstate"
  }
}

data "azurerm_client_config" "current" {}