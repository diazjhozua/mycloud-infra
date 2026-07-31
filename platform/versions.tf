terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-mycloud-tfstate"
    storage_account_name = "stmycloudtfstate"
    container_name       = "tfstate"
    key                  = "platform.tfstate"
    use_azuread_auth     = true
  }
}
