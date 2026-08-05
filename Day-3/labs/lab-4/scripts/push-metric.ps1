# Push a gauge to Prometheus Pushgateway (batch-job style).
# Usage:
#   .\scripts\push-metric.ps1 -Name lab_batch_duration_seconds -Value 3.14
#   .\scripts\push-metric.ps1 -Name lab_batch_duration_seconds -Value 1.2 -Instance student-a

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [double]$Value,

    [string]$Job = "lab4",
    [string]$Instance = "student1",
    [string]$PushgatewayUrl = "http://localhost:9091"
)

$uri = "$PushgatewayUrl/metrics/job/$Job/instance/$Instance"
$payload = @"
# TYPE $Name gauge
# HELP $Name Custom value pushed from lab-4 script
$Name $Value
"@

Write-Host "POST $uri"
Write-Host $payload

Invoke-RestMethod -Method Post -Uri $uri -ContentType "text/plain" -Body $payload
Write-Host "Pushed $Name=$Value (job=$Job instance=$Instance)"
