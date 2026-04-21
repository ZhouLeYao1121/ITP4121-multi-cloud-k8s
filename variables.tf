variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "eastasia"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "asia-east1"
}

variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
}

variable "cluster_name" {
  type    = string
  default = "itp4121-single"
}
