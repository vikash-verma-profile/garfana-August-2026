# Lab 2 - Version, Export, Import & Provision

**Course:** Grafana Monitoring & Observability - Day 4  
**Module:** Dashboard Management (Hands-on Lab 15)  
**Duration:** ~25–35 minutes

---

## Objectives

1. Use dashboard **version history** (save, diff, restore)
2. **Export for sharing externally** and inspect `__inputs`
3. **Import** a copy into Sandbox with a new UID
4. Export via the **HTTP API** with a service account token
5. Prove **file provisioning** is read-only and auto-reloads

---

## Step 0 - Start the stack

Stop other Grafana containers first if needed, then:

```bash
cd labs/lab-2
docker compose up -d
```

Login: http://localhost:3000 - `admin` / `admin`  
Confirm provisioned board: **Dashboards → Production → Platform · Node Health**

Note: `allowUiUpdates: false` → Save is disabled on provisioned dashboards.

---

## Step 1 - Version history on a UI dashboard

1. Create a new dashboard in folder **Sandbox** (or General)
2. Add any panel (Prometheus `up`)
3. Save with message: `v1 initial`
4. Edit the panel title → Save: `v2 retitle`
5. Change refresh to `1m` → Save: `v3 refresh`
6. **Dashboard settings → Versions**
7. Compare v1 vs v3; **Restore** v2 (restore creates a new version)

**Checkpoint:** Version history shows 3+ entries; restore produced a new version.

---

## Step 2 - Export for sharing

1. Open your Sandbox dashboard
2. **Share → Export → Save to file**
3. Tick **Export for sharing externally**
4. Open the JSON and find the `__inputs` block (data source placeholders)

---

## Step 3 - Import into Sandbox

1. **Dashboards → New → Import**
2. Upload the exported file
3. Map data source → **Prometheus**
4. Choose folder **Sandbox**
5. Set a **new UID** (do not collide with `day4-node-health`)
6. Import

**Checkpoint:** Imported copy lives in Sandbox with its own UID.

---

## Step 4 - Export via API

1. **Administration → Users and access → Service accounts → Add**
2. Name: `day4-export` - Role: **Admin** (or Editor)
3. **Add token** → copy once → export:

```powershell
$TOKEN = "glsa_PASTE_HERE"
$GF = "http://localhost:3000"
Invoke-RestMethod -Headers @{ Authorization = "Bearer $TOKEN" } `
  -Uri "$GF/api/dashboards/uid/day4-sandbox-demo" |
  ConvertTo-Json -Depth 50 |
  Set-Content -Path .\exported-sandbox.json
```

Bash:

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$GF/api/dashboards/uid/day4-node-health" | jq . > exported-prod.json
```

---

## Step 5 - Prove provisioning reload

1. Open **Production → Platform · Node Health**
2. Confirm you **cannot Save** in the UI
3. On disk, edit `dashboards/prod/node-health.json` - change the panel title string
4. Wait ≤ 30s (`updateIntervalSeconds`)
5. Refresh the browser - title updates from file

**Checkpoint:** Provisioned dashboard is read-only and auto-reloads from disk.

---

## Step 6 - Folder naming takeaway

Recommended pattern from the deck:

| Folder | Purpose |
|---|---|
| `00 · Executive` | KPI / SLO roll-ups |
| `10 · Platform-Prod` | SRE admin |
| `90 · Sandbox` | Everyone edit |
| `99 · Archive` | Read-only cleanup |

Dashboards as code: Git is source of truth; `allowUiUpdates: false` in production.

---

## Success criteria

- [ ] Version history + restore worked
- [ ] Exported JSON shows `__inputs` when sharing externally
- [ ] Import landed in Sandbox with new UID
- [ ] API export with service account token succeeded
- [ ] File edit appeared in UI without clicking Save

---

## Files

| Path | Purpose |
|---|---|
| `provisioning/dashboards/dashboards.yml` | Provider → Production, read-only |
| `dashboards/prod/node-health.json` | Provisioned dashboard |
| `grafana/auth-github.ini.example` | Optional OAuth sketch for Lab 1/14 |

---

## Next lab

**[Lab 3 - Capstone: Secure, Govern & Tune](../lab-3/STEPS.md)**
