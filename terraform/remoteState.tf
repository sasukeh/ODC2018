terraform {
 backend "azurerm" {
  storage_account_name = "odcterraformblob"
  container_name       = "terraformblobstatefile"
  key                  = "prod.terraform.tfstate"
  access_key           = "2dSCEq9Q3JdGLtrjbGuywpMhXmVpt8Di0yXi0ZAdBsi/RM3YWNPL2E/h7rEVXBuzMvQ+TSCw7UeLqJ18iM+LWA=="
  }
}
