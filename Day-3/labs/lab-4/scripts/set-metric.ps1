# Insert / update a custom metric on the lab custom-metrics API.
# Usage:
#   .\scripts\set-metric.ps1 -Name lab_queue_depth -Value 42
#   .\scripts\set-metric.ps1 -Name lab_queue_depth -Value 7 -Labels @{region="eu";env="lab"}
#   .\scripts\set-metric.ps1 -Name lab_orders_total -Value 150 -Type counter -Labels @{region="lab"}

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [double]$Value,

    [ValidateSet("gauge", "counter")]
    [string]$Type = "gauge",

    [hashtable]$Labels = @{},

    [string]$BaseUrl = "http://localhost:8081"
)

$body = @{
    name   = $Name
    value  = $Value
    type   = $Type
    labels = @{}
}

foreach ($key in $Labels.Keys) {
    $body.labels[$key] = [string]$Labels[$key]
}

$json = $body | ConvertTo-Json -Depth 5
Write-Host "POST $BaseUrl/api/metrics"
Write-Host $json

$response = Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/metrics" -ContentType "application/json" -Body $json
$response | ConvertTo-Json -Depth 5
