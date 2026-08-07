# Raise checkout latency so p95 exceeds the 500ms SLO.
$ErrorActionPreference = "Stop"
Invoke-RestMethod -Method POST -Uri "http://localhost:8080/chaos" `
  -ContentType "application/json" `
  -Body '{"latency_ms": 800, "error_rate": 0.02}' | ConvertTo-Json
Write-Host "Chaos ON: latency_ms=800. Watch Grafana p95 + alert ShopFrontCheckoutP95High."
Write-Host "Reset with: .\chaos-reset.ps1"
