# Return ShopFront API to mild baseline noise.
$ErrorActionPreference = "Stop"
Invoke-RestMethod -Method POST -Uri "http://localhost:8080/chaos" `
  -ContentType "application/json" `
  -Body '{"latency_ms": 0, "error_rate": 0.02}' | ConvertTo-Json
Write-Host "Chaos reset to baseline."
