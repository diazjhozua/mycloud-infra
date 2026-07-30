variable "subscription_id" {
  description = "Azure subscription to deploy into. Supplied via terraform.tfvars (gitignored) so the public repo stays ID-free."
  type        = string
}

variable "location" {
  description = "Default Azure region for resources."
  type        = string
  default     = "southeastasia"
}

variable "unique_suffix" {
  description = "Suffix appended to globally-unique resource names (SQL server, web app) to avoid DNS collisions."
  type        = string
  default     = "jhozua"
}

variable "smtp_host" {
  description = "SMTP server hostname."
  type        = string
  default     = "smtp.gmail.com"
}

variable "smtp_port" {
  description = "SMTP server port (587 = STARTTLS)."
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP login — for Gmail, the full gmail address. Supplied via terraform.tfvars."
  type        = string
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP password — for Gmail, a 16-character app password (not the account password). Supplied via terraform.tfvars."
  type        = string
  sensitive   = true
}

variable "smtp_from_email" {
  description = "Sender address for outgoing mail — for Gmail, must match the account address."
  type        = string
}
