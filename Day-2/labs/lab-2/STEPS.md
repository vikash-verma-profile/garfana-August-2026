# Lab 2 - Service Health Dashboard (Variables & Panels)

**Course:** Grafana Monitoring & Observability - Day 2  
**Modules:** Dashboard Creation + Visualization Panels  
**Duration:** ~45–60 minutes  
**Depends on:** [Lab 1](../lab-1/STEPS.md) stack running (Grafana + Prometheus + PostgreSQL)

---

## Objectives

By the end of this lab you will be able to:

1. Create folder **Training** and dashboard **Day 2 - Service Health**
2. Add Query and Interval template variables (`instance`, interval)
3. Build five panels: Stat (`up`), Time series (CPU), Gauge (memory %), Bar gauge (by instance), Table (SQL)
4. Group panels into two collapsible rows
5. Export dashboard JSON for Day 3 homework

---

## Prerequisites

```bash
cd ../lab-1
docker compose ps
# If stopped:
docker compose up -d
```

Login: [http://localhost:3000](http://localhost:3000) - `admin` / `admin`

---

## Design principles reminder (Module 7)

- One dashboard, one question → *“Is this host healthy right now, and how has it behaved recently?”*
- Top-left = health summary; detail below
- Five to nine panels (you will add five)
- Always set **units** and **thresholds**
- Multi-value variables → match with `=~`, never `=`

---

## Step 1 - Create the dashboard shell

1. **Dashboards → New → New folder** → name: `Training`
2. **Dashboards → New → New dashboard**
3. Open **Dashboard settings** (gear)
4. **Name:** `Day 2 - Service Health`
5. **Folder:** Training
6. **Time range:** Last 6 hours
7. **Auto-refresh:** 30s
8. **Save dashboard**

**Checkpoint (deck task 3):** Dashboard listed under the Training folder.

---

## Step 2 - Add variables

Open **Settings → Variables → Add variable**.

### Variable A - `instance` (Query)

| Setting | Value |
|---|---|
| Name | `instance` |
| Type | Query |
| Data source | Prometheus |
| Query | `label_values(node_uname_info, instance)`  
  (fallback: `label_values(node_cpu_seconds_total, instance)`) |
| Multi-value | On |
| Include All option | On |

### Variable B - `interval` (Interval)

| Setting | Value |
|---|---|
| Name | `interval` |
| Type | Interval |
| Values | `1m,5m,1h` (or use defaults + custom) |

Save the dashboard.

**Checkpoint (deck task 4):** The `instance` dropdown lists your scraped target(s).

---

## Step 3 - Row: Overview - Stat panel (`up`)

1. **Add → Row** → title `Overview`
2. **Add → Visualization**
3. Data source: **Prometheus**
4. Query (Code mode):

```promql
up{job="node", instance=~"$instance"}
```

5. Visualization: **Stat**
6. Panel title: `Target Up`
7. Query options: **Instant** (or Stat with last/instant calc)
8. Unit: none / short; thresholds: Red below 1, Green at/above 1
9. Apply

---

## Step 4 - Time series: CPU busy %

Still in Overview (or expand Overview):

1. Add visualization - Prometheus
2. Query:

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[$__rate_interval])) * 100)
```

> Prefer `$__rate_interval` over a hardcoded `[5m]` so zoom adapts (Module 6 tip).

3. Visualization: **Time series**
4. Title: `CPU Busy %`
5. Unit: Percent (0–100)
6. Legend: `{{instance}}`
7. Apply

---

## Step 5 - Gauge: Memory available %

1. Add visualization - Prometheus
2. Query:

```promql
100 * (node_memory_MemAvailable_bytes{instance=~"$instance"} / node_memory_MemTotal_bytes{instance=~"$instance"})
```

3. Visualization: **Gauge**
4. Title: `Memory Available %`
5. Unit: Percent (0–100)
6. Thresholds example: Red &lt; 10, Orange &lt; 25, Green ≥ 25 (available %)
7. Apply

---

## Step 6 - Bar gauge: CPU by instance

1. Add visualization - Prometheus
2. Query (same CPU busy expression as Step 4)
3. Visualization: **Bar gauge**
4. Title: `CPU by Instance`
5. Calculation: Last / Mean as appropriate
6. Orientation: Horizontal
7. Apply

---

## Step 7 - Row: Business / Database - SQL Table

1. **Add → Row** → title `Database` (leave collapsed after saving if you want the performance tip from the deck)
2. Add visualization - data source **PostgreSQL**
3. Format as: **Table**
4. Query:

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

5. Title: `Slowest Endpoints (SQL)`
6. Apply

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

## Step 8 - Polish layout

1. Drag panels so Overview holds Stat / Time series / Gauge / Bar gauge
2. Database row holds the SQL table
3. Collapse the Database row and confirm queries for collapsed panels pause (Module 7)
4. Change `instance` (if multiple) and confirm every PromQL panel updates
5. Save with message: `Day2 lab panels complete`

**Checkpoint (deck task 5):** All five panel types render with no query errors.

---

## Step 9 - Export JSON (homework bridge)

1. Share / Export → **Export** → Save to file  
   Optional: tick **Export for sharing externally**
2. Keep the file for Day 3 / Day 4 provisioning practice
3. Optional: open **Dashboard settings → JSON Model** and find `templating` and `panels`

---

## Done when… (from the deck)

- [ ] Both data sources Save & test green (Lab 1)
- [ ] One dashboard uses **both** Prometheus and PostgreSQL
- [ ] Changing `instance` updates Prometheus panels
- [ ] Panels sit in **two** collapsible rows
- [ ] Dashboard saved and JSON exported

---

## Optional stretch

- Create a **library panel** from the CPU Time series (Panel menu → More → Create library panel)
- Add a Pie chart of `status` counts from `orders`
- Import community dashboard **Node Exporter Full** (ID `1860`) into Training and compare design vs your board

---

## Files in this lab

| File | Purpose |
|---|---|
| `STEPS.md` | This document |
| `docker-compose.yml` | Optional alternate stack with sample provisioned dashboard |
| `dashboards/day2-service-health.json` | Starter/reference dashboard (provisioned if using Lab 2 Compose) |

---

## Coming in Day 3

- Deeper PromQL / SQL in Explore + Query Inspector
- Transformations (Join, Reduce, Organize fields)
- Unified Alerting, contact points, notification policies
