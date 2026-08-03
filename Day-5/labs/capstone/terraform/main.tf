terraform {
  required_version = ">= 1.5"
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}

variable "grafana_url" {
  type    = string
  default = "http://localhost:3000"
}

variable "grafana_auth" {
  type      = string
  sensitive = true
}

resource "grafana_folder" "platform" {
  title = "Platform"
  uid   = "platform"
}

resource "grafana_folder" "payments" {
  title = "Payments"
  uid   = "payments"
}

resource "grafana_team" "payments" {
  name = "Team-Payments"
}

# After you create users, add memberships and uncomment permissions:
# resource "grafana_folder_permission" "payments_editor" {
#   folder_uid = grafana_folder.payments.uid
#   permissions {
#     team_id    = grafana_team.payments.id
#     permission = "Edit"
#   }
# }
