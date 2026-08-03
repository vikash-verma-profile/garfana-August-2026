# Lab 3 - Capstone: Secure, Govern & Tune

**Course:** Grafana Monitoring & Observability - Day 4  
**Capstone Lab 4** (deck) - five task blocks  
**Duration:** ~45–60 minutes · pairs  

---

## Objectives

Complete blocks **A → E** in order on one instance:

| Block | Focus | Time |
|---|---|---|
| A | Create users & teams | ~8 min |
| B | Configure folder RBAC | ~10 min |
| C | Import dashboards | ~8 min |
| D | Export & provision read-only | ~9 min |
| E | Optimize queries | ~10 min |

---

## Environment

```bash
# Stop other stacks using port 3000 first
cd labs/lab-3
docker compose up -d
```

- Grafana http://localhost:3000 - `admin` / `admin`
- Prometheus data source pre-provisioned as **Prometheus**
- Repo folder `grafana-gitops/` is mounted for provisioning
- Use a **second private browser window** for Viewer tests
- Flag a blocker after 3 minutes - do not sit stuck

---

## Block A - Create users & teams (8 min)

Create four local users (org role **Viewer** unless noted):

| Login | Suggested role intent |
|---|---|
| `viewer1` | Viewer |
| `editor1` | Editor |
| `admin1` | Admin (org) - optional; prefer fewer admins |
| `analyst1` | Viewer (will join BI team) |

Create teams:

1. `Platform-SRE` - add `editor1` (and admin if used)
2. `BI-Analysts` - add `analyst1`

Optional: set a team home dashboard preference after Block C.

**Checkpoint:** Teams list shows both teams with members.

---

## Block B - Configure RBAC (10 min)

1. Ensure folders exist (Compose may already create **Production** / **Business** via `foldersFromFilesStructure`):
   - `Production`
   - `Business`
2. On **Production** permissions:
   - Remove blanket **Editor**
   - `Platform-SRE` = **Edit** (or Admin)
   - `BI-Analysts` = **View** (or no access - deck variant: BI sees Business only)
3. On **Business**:
   - `BI-Analysts` = **Edit** or **View**
   - Remove Production access for BI if testing isolation
4. Verify with `viewer1` / `analyst1` private-window logins

**Definition of done (partial):**

- Viewer sees Production but cannot edit
- BI-Analysts focus on Business (tighten ACLs until this is true)

> Org role Editor overrides folder “view only” intentions - keep test users at **Viewer** org role.

---

## Block C - Import dashboards (8 min)

1. **Dashboards → Import →** grafana.com ID **`1860`** (Node Exporter Full) into **Production**
2. Map data source → Prometheus
3. Import `grafana-gitops` JSON or any Day-2 export into **Business**
4. Confirm both render with live data

**Checkpoint:** Both dashboards show live Prometheus data.

---

## Block D - Export & provision (9 min)

1. Export both dashboards with **Export for sharing externally**
2. Copy cleaned JSON into:

```text
grafana-gitops/dashboards/Production/
grafana-gitops/dashboards/Business/
```

3. Ensure each file has `"id": null` and a stable `"uid"`
4. Confirm provider YAML has `allowUiUpdates: false` (already set)
5. Wait for reload / restart Grafana if needed:

```bash
docker compose restart grafana
```

6. Open provisioned dashboards → **Cannot save** in UI

**Checkpoint:** Provisioned dashboards show “Cannot save” / read-only.

---

## Block E - Optimize queries (10 min)

1. Open the heaviest panel (often community dashboard 1860)
2. **Inspect → Query** - note duration and response size
3. Apply improvements:
   - Aggregate in PromQL (`sum by`, `rate`, `$__rate_interval`)
   - Cap **Max data points** (~ panel width, e.g. 800)
   - Set dashboard refresh to **1m** (instance floor is 30s via env)
   - Collapse drill-down rows
4. Re-measure with Query Inspector

**Checkpoint:** Slowest panel query time reduced measurably; refresh ≥ 1m.

---

## Definition of done (full)

1. Viewer login sees Production but cannot edit  
2. BI-Analysts sees Business appropriately (not full Production edit)  
3. Dashboards render with live Prometheus data  
4. Provisioned dashboards cannot be saved in UI  
5. Slowest panel improved in Inspector stats  
6. Dashboard refresh no faster than 1m  

---

## Troubleshooting

| Issue | Fix |
|---|---|
| Dashboard missing after provisioning | Check logs, YAML indent, mount path |
| Viewer still edits everything | Org role is Editor/Admin - set Viewer |
| Import asks for data source | Map `__inputs` to Prometheus |
| Refresh 5s blocked | `GF_DASHBOARDS_MIN_REFRESH_INTERVAL=30s` |

---

## Stretch goals

- Service account token + `POST /api/dashboards/db`
- Enable query caching on Prometheus DS (Enterprise feature - skip on OSS if unavailable)
- Break-glass drill: document how you would recover admin access

---

## Cleanup

```bash
docker compose down -v
```
