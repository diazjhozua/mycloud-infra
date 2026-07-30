locals {
  project = "tydee"

  # Deliberately a local, not a variable: the folder IS the environment.
  # This prevents ever applying prd names against the stg state file.
  environment = "stg"

  name = "${local.project}-${local.environment}"

  tags = {
    project     = local.project
    environment = local.environment
    managed_by  = "terraform"
    repo        = "mycloud-infra"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

# ---------- Database (Azure SQL free offer) ----------

resource "random_password" "sql_admin" {
  length           = 24
  special          = true
  override_special = "!#-_" # avoid chars that break connection strings (; = , ')
}

resource "azurerm_mssql_server" "this" {
  name                         = "sql-${local.name}-${var.unique_suffix}" # globally unique DNS name
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = "tydeeadmin"
  administrator_login_password = random_password.sql_admin.result
  minimum_tls_version          = "1.2"
  tags                         = local.tags
}

# Lets the App Service (and other Azure services) reach the SQL server.
# 0.0.0.0 is the special "Azure services" rule, not "the whole internet".
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Created via azapi because azurerm can't set useFreeLimit, and the free offer
# can only be applied at creation time — an existing database can't be converted.
resource "azapi_resource" "db" {
  type      = "Microsoft.Sql/servers/databases@2023-08-01-preview"
  name      = "db-${local.name}"
  parent_id = azurerm_mssql_server.this.id
  location  = azurerm_resource_group.this.location
  tags      = local.tags

  body = {
    sku = {
      # Free offer requires this exact serverless SKU (General Purpose, Gen5, 2 vCores)
      name     = "GP_S_Gen5"
      tier     = "GeneralPurpose"
      family   = "Gen5"
      capacity = 2
    }
    properties = {
      collation                   = "SQL_Latin1_General_CP1_CI_AS"
      maxSizeBytes                = 34359738368 # 32 GB, the free offer maximum
      minCapacity                 = 0.5
      autoPauseDelay              = 60 # minutes idle before pausing (saves vCore quota)
      useFreeLimit                = true
      freeLimitExhaustionBehavior = "AutoPause" # pause instead of billing when the monthly quota runs out
      zoneRedundant               = false
    }
  }
}

# ---------- Backend API (.NET on App Service F1) ----------

resource "azurerm_service_plan" "this" {
  name                = "plan-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = local.tags
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false # plain alphanumeric — the key is read as raw UTF-8 bytes
}

locals {
  api_name     = "app-${local.name}-api-${var.unique_suffix}" # globally unique DNS name
  api_url      = "https://${local.api_name}.azurewebsites.net"
  frontend_url = "https://${azurerm_static_web_app.client.default_host_name}"
}

resource "azurerm_linux_web_app" "api" {
  name                = local.api_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  site_config {
    always_on         = false # not supported on F1
    use_32_bit_worker = true  # F1 only supports 32-bit workers

    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = {
    # Double underscore maps to the ":" hierarchy in .NET configuration
    "ConnectionStrings__Database" = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Initial Catalog=${azapi_resource.db.name};User ID=${azurerm_mssql_server.this.administrator_login};Password=${random_password.sql_admin.result};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

    "Jwt__Secret"   = random_password.jwt_secret.result
    "Jwt__Issuer"   = local.api_url
    "Jwt__Audience" = local.frontend_url

    "Cors__AllowedOrigins__0" = local.frontend_url # array entries use the index

    "Smtp__Host"         = var.smtp_host
    "Smtp__Port"         = tostring(var.smtp_port)
    "Smtp__Username"     = var.smtp_username
    "Smtp__Password"     = var.smtp_password
    "Smtp__FromEmail"    = var.smtp_from_email
    "Smtp__AppName"      = "Tydee"
    "Smtp__FrontendUrl"  = local.frontend_url
    "Smtp__IsProduction" = "true"
  }

  tags = local.tags
}

# ---------- Frontend (Static Web App, Free tier) ----------

resource "azurerm_static_web_app" "client" {
  name                = "swa-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = "eastasia" # SWA is only offered in a few regions; southeastasia isn't one
  sku_tier            = "Free"
  sku_size            = "Free"

  app_settings = {
    # Server-side only (Next.js route handlers) — NEXT_PUBLIC_API_URL is not set
    # here because build-time vars are stamped in by the CI build, not at runtime.
    "API_URL" = local.api_url
  }

  tags = local.tags
}
