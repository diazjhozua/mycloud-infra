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
