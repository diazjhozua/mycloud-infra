data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "tydee_stg" {
  name = "rg-tydee-stg"
}

data "azurerm_resource_group" "tfstate" {
  name = "rg-mycloud-tfstate"
}

# Layer 1 — subscription-wide safety net: catches spend ANYWHERE in the
# subscription, including resource groups that don't exist yet.
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-sub-monthly"
  subscription_id = data.azurerm_subscription.current.id
  amount          = 5
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-07-01T00:00:00Z" # must be the first of a month
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  # Fires early, when the month's trend predicts an overshoot
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }
}

# Layer 2 — anomaly detection: baseline spend is ~$0, so any deviation alerts.
resource "azurerm_cost_anomaly_alert" "daily" {
  name            = "cost-anomaly-alert"
  display_name    = "Daily cost anomaly alert"
  subscription_id = data.azurerm_subscription.current.id
  email_subject   = "Azure cost anomaly detected"
  email_addresses = [var.alert_email]
}

# Layer 3 — per-RG budgets so alert emails identify the culprit.
resource "azurerm_consumption_budget_resource_group" "tydee_stg" {
  name              = "budget-rg-tydee-stg"
  resource_group_id = data.azurerm_resource_group.tydee_stg.id
  amount            = 2
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-07-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }
}

resource "azurerm_consumption_budget_resource_group" "tfstate" {
  name              = "budget-rg-mycloud-tfstate"
  resource_group_id = data.azurerm_resource_group.tfstate.id
  amount            = 1
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-07-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }
}
