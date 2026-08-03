# Creates service account "automation" and prints a token.
# Usage: .\01-create-token.ps1

$ErrorActionPreference = "Stop"
$GF = if ($env:GF) { $env:GF } else { "http://localhost:3000" }
$basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:admin"))
$headers = @{
  Authorization  = "Basic $basic"
  "Content-Type" = "application/json"
}

$existing = Invoke-RestMethod -Uri "$GF/api/serviceaccounts/search?query=automation" -Headers @{ Authorization = "Basic $basic" }
$saId = $null
if ($existing.totalCount -gt 0) {
  $saId = ($existing.serviceAccounts | Where-Object { $_.name -eq "automation" } | Select-Object -First 1).id
}

if (-not $saId) {
  $sa = Invoke-RestMethod -Method POST -Uri "$GF/api/serviceaccounts" -Headers $headers -Body '{"name":"automation","role":"Admin"}'
  $saId = $sa.id
  Write-Host "Created service account id=$saId"
} else {
  Write-Host "Reusing service account id=$saId"
}

$tokenName = "ci-token-" + (Get-Date -Format "yyyyMMddHHmmss")
$token = Invoke-RestMethod -Method POST -Uri "$GF/api/serviceaccounts/$saId/tokens" -Headers $headers -Body (@{ name = $tokenName } | ConvertTo-Json)
Write-Host "TOKEN=$($token.key)"
Write-Host "Export: `$env:TOKEN='$($token.key)'; `$env:GF='$GF'"
