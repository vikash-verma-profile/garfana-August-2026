#!/usr/bin/env bash
# Capstone backup sketch - adapt paths to your Compose project name / volume.
set -euo pipefail
STAMP=$(date +%F_%H%M%S)
DEST="./backups/backup-$STAMP"
mkdir -p "$DEST"

echo "Stop Grafana for consistent SQLite snapshot"
docker compose stop grafana

VOL=$(docker inspect grafana --format '{{range .Mounts}}{{if eq .Destination "/var/lib/grafana"}}{{.Name}}{{end}}{{end}}')
docker run --rm -v "$VOL:/data:ro" -v "$DEST:/backup" alpine \
  sh -c 'cp -a /data/grafana.db /backup/grafana.db || cp -a /data/. /backup/data/'

cp -a ../provisioning "$DEST/" 2>/dev/null || true
cp -a ../dashboards "$DEST/" 2>/dev/null || true

docker compose start grafana
echo "Backup written to $DEST - record restore elapsed time after a real drill."
echo "$DEST"
