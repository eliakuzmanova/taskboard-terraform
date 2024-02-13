terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.89.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "task-board-RG" {
  name     = "${var.resource_group_name}${random_integer.ri.result}"
  location = var.resource_group_location
}

resource "azurerm_service_plan" "task-board-service_plan" {
  name                ="${var.app_service_plan_name}_${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.task-board-RG.name
  location            = azurerm_resource_group.task-board-RG.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "task-board-web_app" {
  name                = "${var.app_service_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.task-board-RG.name
  location            = azurerm_service_plan.task-board-service_plan.location
  service_plan_id     = azurerm_service_plan.task-board-service_plan.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.task-board-server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.task-board-server_db.name};User ID=${azurerm_mssql_server.task-board-server.administrator_login};Password=${azurerm_mssql_server.task-board-server.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

resource "azurerm_app_service_source_control" "task-board-SC" {
  app_id                 = azurerm_linux_web_app.task-board-web_app.id
  repo_url               = var.repo_URL
  branch                 = "main"
  use_manual_integration = true
}

resource "azurerm_mssql_server" "task-board-server" {
  name                         = "${var.sql_server_name}-${random_integer.ri.result}"
  resource_group_name          = azurerm_resource_group.task-board-RG.name
  location                     = azurerm_resource_group.task-board-RG.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "task-board-server_db" {
  name           = "${var.sql_database_name}_${random_integer.ri.result}"
  server_id      = azurerm_mssql_server.task-board-server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_firewall_rule" "task-board-firewall" {
  name             = "${var.firewall_rule_name}_${random_integer.ri.result}"
  server_id        = azurerm_mssql_server.task-board-server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}