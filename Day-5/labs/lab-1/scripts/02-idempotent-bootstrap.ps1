# Idempotent folder + datasource + dashboard bootstrap.
# Requires: $env:TOKEN and $env:GF (see 01-create-token.ps1)

$ErrorActionPreference = "Stop"
if (-not $env:TOKEN) { throw "Set `$env:TOKEN first (run 01-create-token.ps1)" }
$GF = if ($env:GF) { $env:GF } else { "http://localhost:3000" }
$H = @{
  Authorization  = "Bearer $env:TOKEN"
  "Content-Type" = "application/json"
}
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# scripts -> lab-1
$lab = Split-Path $PSScriptRoot -Parent

function Invoke-Grafana($Method, $Path, $Body) {
  $uri = "$GF$Path"
  if ($Body) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $H -Body $Body
  }
  return Invoke-RestMethod -Method $Method -Uri $uri -Headers @{ Authorization = "Bearer $env:TOKEN" }
}

try { Invoke-Grafana POST /api/folders '{"uid":"lab-api","title":"Lab · API"}' | Out-Null }
catch { Write-Host "Folder may already exist: $($_.Exception.Message)" }

try { Invoke-Grafana POST /api/datasources (Get-Content "$lab\payloads\datasource-prom.json" -Raw) | Out-Null }
catch { Write-Host "Datasource may already exist: $($_.Exception.Message)" }

Invoke-Grafana POST /api/dashboards/db (Get-Content "$lab\payloads\dashboard-v1.json" -Raw) | Out-Null
Write-Host "Bootstrap complete. Dashboard uid=lab-api-1 in folder lab-api"
