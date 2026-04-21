variable "azure_subscription_id" {
  type      = string
  sensitive = true
}
variable "azure_tenant_id" {
  type      = string
  sensitive = true
}
variable "azure_client_id" {
  type      = string
  sensitive = true
}
variable "azure_client_secret" {
  type      = string
  sensitive = true
}

variable "gcp_project_id" {
  type = string
}
variable "gcp_region" {
  type    = string
  default = "asia-east1"
}
variable "azure_region" {
  type    = string
  default = "East Asia"
}
