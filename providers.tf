terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113"
    }
  }
  # Local backend - state files will be stored locally
}

provider "azurerm" {
  features {}
}