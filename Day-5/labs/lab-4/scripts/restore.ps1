# Restore grafana.db from a backup folder created by backup.ps1
# Usage: .\restore.ps1 -BackupDir ..\backups\backup-YYYY-MM-DD_HHMMSS

param(
  [Parameter(Mandatory = $true)]
  [string]$BackupDir
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$db = Join-Path $BackupDir "grafana.db"
if (-not (Test-Path $db)) { throw "No grafana.db in $BackupDir" }

docker compose -f (Join-Path $root "docker-compose.yml") stop grafana

$volume = docker inspect grafana --format "{{range .Mounts}}{{if eq .Destination \"/var/lib/grafana\"}}{{.Name}}{{end}}{{end}}"
Write-Host "Restoring into volume $volume"

docker run --rm -v "${volume}:/data" -v "${BackupDir}:/backup" alpine `
  sh -c "cp /backup/grafana.db /data/grafana.db && chown 472:472 /data/grafana.db || true"

docker compose -f (Join-Path $root "docker-compose.yml") start grafana
Write-Host "Restore complete. Open https://localhost/ and verify dashboards."
