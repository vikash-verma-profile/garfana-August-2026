# Lab 4 - Harden It, Break It, Restore It

**Course:** Grafana Monitoring & Observability - Day 5  
**Module:** Production Best Practices (Lab 4 · 25 min)  
**Duration:** ~25–35 minutes

---

## Objectives

1. Put **Nginx** in front of Grafana with a self-signed certificate
2. Confirm `root_url` / `cookie_secure` / forwarded headers
3. Enable Grafana **metrics**, scrape `/metrics` from Prometheus
4. Take a full backup; break it; restore and time the drill

---

## Step 0 - Certificates

```powershell
cd labs/lab-4
.\scripts\generate-certs.ps1
```

Or bash: `bash ./scripts/generate-certs.sh`

Stop other stacks using 3000/443/80/9090, then:

```bash
docker compose up -d
```

Note: Grafana is **not** published on host :3000 in this lab - only via Nginx **https://localhost/**.

---

## Step 1 - HTTPS via Nginx

1. Open https://localhost/ (accept the browser warning for the self-signed cert)
2. Login `admin` / `admin`
3. Log out and back in - session cookies should be secure
4. Create a temporary dashboard and use **Share** - link should use `https://localhost/...`

Health through the proxy:

```powershell
curl.exe -k https://localhost/api/health
```

---

## Step 2 - Headers / root_url proof

If login loops:

- Check `grafana/grafana.ini` `root_url = https://localhost/`
- Check Nginx sets `X-Forwarded-Proto $scheme`
- `curl.exe -k -I https://localhost/login`

---

## Step 3 - Monitor Grafana itself

1. Prometheus targets: http://localhost:9090/targets - job `grafana` UP
2. In Explore (via https://localhost), query:

```promql
grafana_http_request_duration_seconds_count
```

or

```promql
up{job="grafana"}
```

3. Optional: Import Grafana self-monitoring community dashboard and map Prometheus

---

## Step 4 - Full backup

```powershell
.\scripts\backup.ps1
```

Note the printed backup folder path under `backups/`.

What must be saved (deck):

- Database (`grafana.db`)
- `grafana.ini` / provisioning tree
- Secret key (lives inside grafana data - keep volume backups consistent)
- TLS certs + Nginx config
- Plugins (if any)

---

## Step 5 - Break it deliberately

1. In the UI, **delete** a dashboard you care about (or create one named `Break-Me` first and delete it)
2. Optionally: `docker compose stop grafana`

---

## Step 6 - Restore and time it

```powershell
$sw = [Diagnostics.Stopwatch]::StartNew()
.\scripts\restore.ps1 -BackupDir .\backups\backup-YOUR_STAMP
$sw.Stop()
Write-Host "Restore elapsed minutes:" ($sw.Elapsed.TotalMinutes)
```

1. Open https://localhost/
2. Confirm the deleted dashboard is back
3. Write down elapsed time (homework artifact)

**Done when:** UI answers on HTTPS, `/metrics` is scraped, and the deleted dashboard is back from **your** backup.

---

## Stretch

- Second Grafana instance on shared Postgres + `ha_peers`
- Automate cert renewal reload for Nginx

---

## Troubleshooting playbook (quick)

| Symptom | First move |
|---|---|
| Login redirect loop | Fix `root_url` / `X-Forwarded-Proto` |
| Panel No data | Explore query; check DS URL inside Docker network |
| DS broken after restore | `secret_key` mismatch - restore matching data dir |
| Duplicate alerts in HA | Configure `ha_peers` |

---

## Next

**[Capstone - Observability Stack as Code](../capstone/STEPS.md)**
