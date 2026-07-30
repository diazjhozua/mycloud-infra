terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    # azurerm doesn't support the SQL free offer yet (hashicorp/terraform-provider-azurerm#23438),
    # so the database is created with azapi, which calls the ARM REST API directly.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-mycloud-tfstate"
    storage_account_name = "stmycloudtfstate"
    container_name       = "tfstate"
    key                  = "tydee-stg.tfstate" # backend blocks can't use variables — key is hardcoded per folder
    use_azuread_auth     = true
  }
}
