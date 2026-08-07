terraform {
  required_version = ">= 1.5"
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

# Prefer env vars:
#   GRAFANA_URL=http://localhost:3000
#   GRAFANA_AUTH=glsa_...
provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}

variable "grafana_url" {
  type        = string
  description = "Grafana base URL"
  default     = "http://localhost:3000"
}

variable "grafana_auth" {
  type        = string
  description = "Service account token (set TF_VAR_grafana_auth or pass -var). Lab shortcut: admin:admin"
  sensitive   = true
  default="" # add your service account
}
