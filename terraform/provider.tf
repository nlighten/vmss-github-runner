terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.11.0"
    }
  }

  # backend "azurerm" {
  #   container_name = "tfstate"
  #   key            = "dummy.tfstate"
  # }

}

provider "azurerm" {
  features {
  }
  skip_provider_registration = true
}


