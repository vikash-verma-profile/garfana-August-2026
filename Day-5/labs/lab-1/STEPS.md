# Lab 1 - Drive Grafana from the HTTP API

**Course:** Grafana Monitoring & Observability - Day 5  
**Module:** Grafana HTTP API (Lab 1 · 20 min)  
**Duration:** ~20–30 minutes

---

## Objectives

1. Create a **service account** + token
2. Call `/api/org` and `/api/health` with the Bearer token
3. Create folder `Lab · API` (`uid: lab-api`)
4. Register Prometheus DS (`uid: prom-lab`) and hit `/health`
5. POST a dashboard twice and read `/versions`

---

## Prerequisites

```bash
cd labs/lab-1
docker compose up -d
```

Or use any running Grafana on :3000 with admin access.

Windows PowerShell is assumed below; bash equivalents are noted.

---

## Step 1 - Mint a service account token

```powershell
$GF = "http://localhost:3000"
$basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:admin"))
$headers = @{ Authorization = "Basic $basic"; "Content-Type" = "application/json" }

$sa = Invoke-RestMethod -Method POST -Uri "$GF/api/serviceaccounts" -Headers $headers `
  -Body '{"name":"automation","role":"Admin"}'
$sa | ConvertTo-Json

$token = Invoke-RestMethod -Method POST -Uri "$GF/api/serviceaccounts/$($sa.id)/tokens" -Headers $headers `
  -Body '{"name":"ci-token"}'
$TOKEN = $token.key
$TOKEN   # copy this; it is shown once
$env:TOKEN = $TOKEN
$env:GF = $GF
```

Bash:

```bash
export GF=http://localhost:3000
curl -s -u admin:admin -H 'Content-Type: application/json' \
  -d '{"name":"automation","role":"Admin"}' \
  $GF/api/serviceaccounts
# note id, then:
curl -s -u admin:admin -H 'Content-Type: application/json' \
  -d '{"name":"ci-token"}' \
  $GF/api/serviceaccounts/2/tokens
export TOKEN=glsa_xxx
```

Or run: `.\scripts\01-create-token.ps1`

---

## Step 2 - Prove the token works

```powershell
$H = @{ Authorization = "Bearer $env:TOKEN" }
Invoke-RestMethod -Headers $H -Uri "$env:GF/api/health"
Invoke-RestMethod -Headers $H -Uri "$env:GF/api/org"
```

Both should return HTTP 200 JSON.

---

## Step 3 - Create folder

```powershell
Invoke-RestMethod -Method POST -Headers ($H + @{"Content-Type"="application/json"}) `
  -Uri "$env:GF/api/folders" `
  -Body '{"uid":"lab-api","title":"Lab · API"}'
```

---

## Step 4 - Register Prometheus data source

```powershell
Invoke-RestMethod -Method POST -Headers ($H + @{"Content-Type"="application/json"}) `
  -Uri "$env:GF/api/datasources" `
  -Body (Get-Content .\payloads\datasource-prom.json -Raw)

Invoke-RestMethod -Headers $H -Uri "$env:GF/api/datasources/uid/prom-lab/health"
```

---

## Step 5 - Create dashboard (overwrite:true)

```powershell
Invoke-RestMethod -Method POST -Headers ($H + @{"Content-Type"="application/json"}) `
  -Uri "$env:GF/api/dashboards/db" `
  -Body (Get-Content .\payloads\dashboard-v1.json -Raw)
```

---

## Step 6 - Update title → version 2

```powershell
Invoke-RestMethod -Method POST -Headers ($H + @{"Content-Type"="application/json"}) `
  -Uri "$env:GF/api/dashboards/db" `
  -Body (Get-Content .\payloads\dashboard-v2.json -Raw)

Invoke-RestMethod -Headers $H -Uri "$env:GF/api/dashboards/uid/lab-api-1/versions"
```

**Done when:** Dashboard appears under **Lab · API**, versions show **2**, and you never used the UI to create it.

---

## Codes to know

| Code | Meaning |
|---|---|
| 200 | OK |
| 401 | Bad token |
| 403 | Token role too weak |
| 404 | Wrong uid |
| 412 | Version conflict - re-fetch or `overwrite:true` |

---

## Stretch

Wrap steps 3–5 in `scripts/02-idempotent-bootstrap.ps1` and run it twice safely.

---

## Next lab

**[Lab 2 - Provision from files](../lab-2/STEPS.md)** - stop this stack if ports collide.
