resource "grafana_folder" "tf_lab" {
  title = "TF Lab"
  uid   = "tf-lab"
}

resource "grafana_data_source" "prom" {
  type = "prometheus"
  name = "Prometheus TF"
  uid  = "prom-tf"
  url  = "http://prometheus:9090"

  json_data_encoded = jsonencode({
    httpMethod  = "POST"
    timeInterval = "15s"
  })
}

resource "grafana_dashboard" "tf_lab" {
  folder      = grafana_folder.tf_lab.uid
  config_json = file("${path.module}/dashboards/tf-lab.json")
  overwrite   = true
}
