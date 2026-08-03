# Backup Grafana Docker volume data + compose config tree for Lab 4 restore drill.
# Run from labs/lab-4

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$dest = Join-Path $root "backups\backup-$stamp"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Write-Host "Stopping grafana for consistent SQLite copy..."
docker compose -f (Join-Path $root "docker-compose.yml") stop grafana

$volume = docker volume ls -q | Select-String "lab-4_grafana-data|lab4.*grafana-data|grafana-data" | Select-Object -First 1
if (-not $volume) {
  # Fallback: find volume used by container
  $volume = docker inspect grafana --format "{{range .Mounts}}{{if eq .Destination \"/var/lib/grafana\"}}{{.Name}}{{end}}{{end}}"
}

Write-Host "Copying volume: $volume"
docker run --rm -v "${volume}:/data:ro" -v "${dest}:/backup" alpine `
  sh -c "cp -a /data/grafana.db /backup/grafana.db 2>/dev/null || cp -a /data/. /backup/data/"

Copy-Item (Join-Path $root "grafana\grafana.ini") (Join-Path $dest "grafana.ini") -ErrorAction SilentlyContinue
Copy-Item (Join-Path $root "provisioning") (Join-Path $dest "provisioning") -Recurse -Force
Copy-Item (Join-Path $root "nginx") (Join-Path $dest "nginx") -Recurse -Force
Copy-Item (Join-Path $root "certs") (Join-Path $dest "certs") -Recurse -Force -ErrorAction SilentlyContinue

# Record secret key if present inside volume copy
"Backup created at $stamp" | Set-Content (Join-Path $dest "README.txt")
"IMPORTANT: secret_key must match or encrypted DS passwords break." | Add-Content (Join-Path $dest "README.txt")

docker compose -f (Join-Path $root "docker-compose.yml") start grafana
Write-Host "Backup ready: $dest"
Write-Host $dest
