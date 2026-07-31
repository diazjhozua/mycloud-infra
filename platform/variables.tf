variable "subscription_id" {
  description = "Azure subscription to deploy into. Supplied via terraform.tfvars (gitignored)."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives budget and anomaly alerts. Supplied via terraform.tfvars to keep it out of the public repo."
  type        = string
}
