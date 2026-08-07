# Spike checkout / API error rate for Scenario A.
$ErrorActionPreference = "Stop"
Invoke-RestMethod -Method POST -Uri "http://localhost:8080/chaos" `
  -ContentType "application/json" `
  -Body '{"latency_ms": 0, "error_rate": 0.25}' | ConvertTo-Json
Write-Host "Chaos ON: error_rate=0.25. Watch error Stat + status bar gauge."
Write-Host "Reset with: .\chaos-reset.ps1"
