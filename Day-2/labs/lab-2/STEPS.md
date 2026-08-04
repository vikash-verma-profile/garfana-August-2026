# Lab 2 — Service Health Dashboard (Variables & Panels)

**Course:** Grafana Monitoring & Observability — Day 2  
**Modules:** Prometheus Integration (build) + start of Dashboard Creation  
**Source:** Day-2.pptx — Hands-on Lab 2 (slides 21–23)  
**Duration:** ~30–45 minutes  
**Depends on:** [Lab 1](../lab-1/STEPS.md) stack running

---

## Objectives

By the end of this lab you will be able to:

1. Confirm Prometheus and PostgreSQL data sources (Save & test)
2. Create folder **Training** and dashboard **Day 2 - Service Health**
3. Add Query and Interval template variables (`instance`, `interval`)
4. Build five panels: Stat (`up`), Time series (CPU), Gauge (memory %), Bar gauge (by instance), Table (SQL)
5. Group panels into two collapsible rows and export JSON

---

## Prerequisites

```powershell
cd c:\Users\admin\Desktop\grafana\Day-2\labs\lab-1
docker compose ps
# If stopped:
docker compose up -d --build
```

| Access | Value |
|---|---|
| Grafana | http://localhost:3000 — `admin` / `admin` |
| Prometheus | http://localhost:9090 |
| PostgreSQL | `postgres:5432` / db `demo` / user `grafana` / password `grafana` |

---

## Lab environment reminder (deck slide 22)

```
Browser → Grafana :3000
            ├── Prometheus → :9090 ← node_exporter :9100
            │                      ← postgres_exporter :9187
            └── PostgreSQL → :5432 (demo)
```

Grafana also queries PostgreSQL directly for business panels — two data sources, one dashboard.

---

## Step 1 — Task 1: Configure Prometheus

> Checkpoint: Prometheus API queried successfully

1. **Connections → Data sources → Prometheus**
2. URL: `http://prometheus:9090`
3. Scrape interval: `15s`
4. **Save & test**

---

## Step 2 — Task 2: Configure PostgreSQL

> Checkpoint: database connection OK

| Field | Value |
|---|---|
| Host | `postgres:5432` |
| Database | `demo` |
| User | `grafana` |
| Password | `grafana` |
| TLS/SSL Mode | `disable` |

**Save & test**.

---

## Step 3 — Task 3: Create the dashboard

> Checkpoint: dashboard listed in Training folder

1. **Dashboards → New → New folder** → name: `Training` (skip if it exists)
2. **Dashboards → New → New dashboard**
3. Open **Dashboard settings** (gear)
4. **Name:** `Day 2 - Service Health`
5. **Folder:** Training
6. **Time range:** Last 6 hours
7. **Auto-refresh:** 30s
8. **Save dashboard**

---

## Step 4 — Task 4: Add variables

> Checkpoint: `instance` dropdown lists your targets

Open **Settings → Variables → Add variable**.

### Variable A — `instance` (Query)

| Setting | Value |
|---|---|
| Name | `instance` |
| Type | Query |
| Data source | Prometheus |
| Query | `label_values(node_uname_info, instance)` |
| Fallback query | `label_values(node_cpu_seconds_total, instance)` |
| Multi-value | On |
| Include All option | On |

### Variable B — `interval` (Interval)

| Setting | Value |
|---|---|
| Name | `interval` |
| Type | Interval |
| Values | `1m,5m,1h` |

Save the dashboard.

**Multi-value gotcha (Module 7):** always match with `=~`, never `=`.

---

## Step 5 — Task 5: Add the panels

> Checkpoint: all five panels render, no errors

### 5a — Row: Overview — Stat (`up`)

1. **Add → Row** → title `Overview`
2. **Add → Visualization** → Prometheus
3. Query (Code mode):

```promql
up{job="node", instance=~"$instance"}
```

4. Visualization: **Stat**
5. Title: `Target Up`
6. Query options: prefer **Instant** (or Last / lastNotNull)
7. Thresholds: Red below 1, Green at/above 1
8. Apply

### 5b — Time series: CPU busy %

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[$__rate_interval])) * 100)
```

| Setting | Value |
|---|---|
| Visualization | Time series |
| Title | `CPU Busy %` |
| Unit | Percent (0–100) |
| Legend | `{{instance}}` |

> Prefer `$__rate_interval` over a hardcoded `[5m]` so zoom adapts.

### 5c — Gauge: Memory available %

```promql
100 * (node_memory_MemAvailable_bytes{instance=~"$instance"} / node_memory_MemTotal_bytes{instance=~"$instance"})
```

| Setting | Value |
|---|---|
| Visualization | Gauge |
| Title | `Memory Available %` |
| Unit | Percent (0–100) |
| Thresholds | Red &lt; 10, Orange &lt; 25, Green ≥ 25 |

### 5d — Bar gauge: CPU by instance

Use the same CPU busy expression as 5b.

| Setting | Value |
|---|---|
| Visualization | Bar gauge |
| Title | `CPU by Instance` |
| Orientation | Horizontal |
| Calculation | Last / Mean |

### 5e — Row: Database — SQL Table

1. **Add → Row** → title `Database`
2. Add visualization — data source **PostgreSQL**, Format as **Table**

```sql
SELECT
  endpoint,
  ROUND(AVG(duration_ms)::numeric, 1) AS avg_ms,
  COUNT(*) AS calls,
  SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS errors_5xx
FROM api_requests
WHERE $__timeFilter(created_at)
GROUP BY endpoint
ORDER BY avg_ms DESC
LIMIT 10;
```

| Setting | Value |
|---|---|
| Title | `Slowest Endpoints (SQL)` |

Optional second SQL panel (orders over time) as Time series:

```sql
SELECT
  $__timeGroup(created_at, '5m') AS time,
  status AS metric,
  COUNT(*) AS value
FROM orders
WHERE $__timeFilter(created_at)
GROUP BY 1, 2
ORDER BY 1;
```

---

## Step 6 — Polish layout

1. Drag panels so Overview holds Stat / Time series / Gauge / Bar gauge
2. Database row holds the SQL table
3. Collapse the Database row — collapsed rows pause their queries (Module 7)
4. Change `instance` (if multiple) and confirm every PromQL panel updates
5. Save with message: `Day2 lab panels complete`

---

## Step 7 — Export JSON (homework bridge)

1. Share / Export → **Export** → Save to file  
   Optional: tick **Export for sharing externally**
2. Keep the file for Day 3 / Day 4 provisioning practice
3. Optional: **Dashboard settings → JSON Model** — find `templating` and `panels`

---

## Done when… (from the deck)

- [ ] Both data sources Save & test green
- [ ] One dashboard uses **both** Prometheus and PostgreSQL
- [ ] Changing `instance` updates Prometheus panels
- [ ] Panels sit in **two** collapsible rows
- [ ] Dashboard saved and JSON exported

---

## Optional stretch

- Create a **library panel** from the CPU Time series (Panel menu → More → Create library panel)
- Add a Pie chart of `status` counts from `orders`
- Import community dashboard **Node Exporter Full** (ID `1860`) into Training and compare design

---

## Design principles reminder (Module 7)

- One dashboard, one question → *“Is this host healthy right now, and how has it behaved recently?”*
- Top-left = health summary; detail below
- Five to nine panels
- Always set **units** and **thresholds**
- Multi-value variables → match with `=~`

---

## Files in this lab

| File | Purpose |
|---|---|
| `STEPS.md` | This document |
| `docker-compose.yml` | Optional alternate stack with sample provisioned dashboard |
| `dashboards/day2-service-health.json` | Reference dashboard (if using Lab 2 Compose) |

> Prefer keeping **Lab 1** Compose running. Only start Lab 2 Compose after `docker compose down` in lab-1 (ports collide).

---

## Next lab

Continue with **[Lab 3 — Host Health Visualizations](../lab-3/STEPS.md)**.
