# Lab 3 - Host Health Dashboard (Visualizations & Library Panels)

**Course:** Grafana Monitoring & Observability - Day 2  
**Modules:** Dashboard Creation + Visualization Panels  
**Source:** Day-2.pptx - Hands-on Lab 3 (slides 36–37)  
**Duration:** ~30–45 minutes  
**Depends on:** [Lab 1](../lab-1/STEPS.md) stack running (data sources from Labs 1–2)

---

## Objectives

By the end of this lab you will be able to:

1. Lay out dashboard **Host Health** with two collapsible rows (`Overview`, `Detail`)
2. Build **Time series**, **Stat**, **Gauge**, **Table**, and **Bar gauge** panels with units and thresholds
3. Add a **Heatmap** (request duration buckets) and a **Geomap** (latitude / longitude from SQL)
4. Save one panel as a **library panel** and reuse it
5. Export dashboard JSON

---

## Prerequisites

```powershell
cd c:\Users\admin\Desktop\grafana\Day-2\labs\lab-1
docker compose ps
# If stopped:
docker compose up -d --build
```

Login: [http://localhost:3000](http://localhost:3000) - `admin` / `admin`

Confirm data sources from Lab 1 still Save & test: **Prometheus**, **PostgreSQL** (Loki optional here).

If Geomap SQL fails with `relation "regions" does not exist` (Lab 1 volume created before that table existed):

```powershell
cd c:\Users\admin\Desktop\grafana\Day-2\labs\lab-1
Get-Content postgres\migrate-regions.sql | docker exec -i postgres psql -U grafana -d demo
```

---

## Choosing the right panel (Module 8 reminder)

| Question | Panel |
|---|---|
| How has it changed over time? | Time series |
| What is the value right now? | Stat / Gauge |
| How do these items compare? | Bar gauge |
| How is it distributed? | Heatmap / Histogram |
| Where is it happening? | Geomap |
| I need the exact numbers | Table |

Set on every panel: **unit**, **decimals**, **thresholds**, readable legend.

---

## Step 1 - Task 1: Lay out the board

> Checkpoint: both rows collapse cleanly

1. **Dashboards → New → New dashboard**
2. Dashboard settings:
   - **Name:** `Host Health`
   - **Folder:** `Training`
   - **Time range:** Last 6 hours
   - **Auto-refresh:** 30s
3. **Add → Row** → title `Overview`
4. **Add → Row** → title `Detail`
5. Click each row chevron and confirm they **collapse / expand**
6. Save

**Checkpoint:** both rows collapse cleanly.

---

## Step 2 - Task 2: Time series panel (CPU)

> Checkpoint: lines named by instance

1. In the **Overview** row, **Add → Visualization** → Prometheus
2. Query:

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])) * 100)
```

3. Visualization: **Time series**
4. Title: `CPU Busy %`
5. Unit: **Percent (0–100)**
6. Decimals: `1`
7. Legend: `{{instance}}`
8. Thresholds: Orange at `70`, Red at `90`
9. Apply

**Checkpoint:** lines named by instance.

---

## Step 3 - Task 3: Stat and Gauge

> Checkpoint: both show live values

### Stat - available memory

```promql
node_memory_MemAvailable_bytes
```

| Setting | Value |
|---|---|
| Visualization | Stat |
| Title | `Memory Available` |
| Unit | bytes (IEC) - e.g. `binB` / bytes(IEC) |
| Calculation | **Last * / lastNotNull** (not Mean of nulls) |
| Optional | sparkline On |

### Gauge - disk used %

```promql
100 - ((node_filesystem_avail_bytes{fstype!="tmpfs",mountpoint="/"} * 100) / node_filesystem_size_bytes{fstype!="tmpfs",mountpoint="/"})
```

> On Docker Desktop / Windows the mountpoint label may differ. If the query is empty, discover labels in Explore:

```promql
node_filesystem_avail_bytes
```

Then adjust `mountpoint` / `device` filters. Fallback (sum across mounts - lab only):

```promql
100 * (1 - (sum(node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"}) / sum(node_filesystem_size_bytes{fstype!~"tmpfs|overlay"})))
```

| Setting | Value |
|---|---|
| Visualization | Gauge |
| Title | `Disk Used %` |
| Min / Max | 0 / 100 |
| Unit | Percent (0–100) |
| Calculation | Last * / lastNotNull |
| Thresholds | Green &lt; 70, Orange &lt; 85, Red ≥ 85 |

**Checkpoint:** both show live values.

---

## Step 4 - Task 4: Table and Bar gauge

> Checkpoint: table sorts and units read right

### Table - top orders from PostgreSQL

Place in the **Detail** row. Data source: **PostgreSQL**, Format as **Table**:

```sql
SELECT
  id,
  status,
  region,
  amount,
  created_at
FROM orders
WHERE $__timeFilter(created_at)
ORDER BY amount DESC
LIMIT 10;
```

| Setting | Value |
|---|---|
| Title | `Top Orders` |
| Override `amount` | Unit = currency USD (or short), Decimals = 2 |

Confirm column sort works in the panel.

### Bar gauge - requests by instance

Prometheus:

```promql
sum by (instance) (rate(http_requests_total[5m]))
```

| Setting | Value |
|---|---|
| Visualization | Bar gauge |
| Title | `Request Rate by Instance` |
| Unit | reqps / ops |
| Orientation | Horizontal |
| Calculation | Last * |

**Checkpoint:** table sorts; bar gauge units readable.

---

## Step 5 - Task 5: Heatmap, Geomap, library panel

> Checkpoint: library panel reused twice

### Heatmap - request duration buckets

1. Still in **Detail**, add visualization → Prometheus
2. Query:

```promql
sum by (le) (rate(http_request_duration_seconds_bucket[5m]))
```

3. Visualization: **Heatmap**
4. In query options / Heatmap settings:
   - Format: **Time series buckets** (or Heatmap → calculate from buckets / `le` label - wording varies by Grafana version)
   - If the panel asks for a histogram format, use **Heatmap** with legend `{{le}}`
5. Title: `Request Duration Heatmap`
6. Apply

Alternate (SQL buckets from `api_requests` if Prom histogram is empty):

```sql
SELECT
  $__timeGroup(created_at, '5m') AS time,
  CASE
    WHEN duration_ms < 50 THEN '0-50ms'
    WHEN duration_ms < 100 THEN '50-100ms'
    WHEN duration_ms < 250 THEN '100-250ms'
    WHEN duration_ms < 500 THEN '250-500ms'
    ELSE '500ms+'
  END AS metric,
  COUNT(*) AS value
FROM api_requests
WHERE $__timeFilter(created_at)
GROUP BY 1, 2
ORDER BY 1;
```

Use **Time series** or **Heatmap** depending on version - the goal is seeing duration distribution over time.

### Geomap - from a latitude field

PostgreSQL, Format as **Table**:

```sql
SELECT
  r.latitude,
  r.longitude,
  o.region,
  COUNT(*) AS orders,
  ROUND(SUM(o.amount)::numeric, 2) AS revenue
FROM orders o
JOIN regions r ON r.region = o.region
WHERE $__timeFilter(o.created_at)
GROUP BY r.latitude, r.longitude, o.region
ORDER BY orders DESC;
```

1. Visualization: **Geomap**
2. Map layers → markers / lookup:
   - Latitude field: `latitude`
   - Longitude field: `longitude`
   - Size / color by `orders` or `revenue` if available
3. Title: `Orders by Region`
4. Apply

### Library panel

1. Open the **CPU Busy %** panel menu → **More → Create library panel**
2. Name: `CPU Busy % (Library)` - folder `Training`
3. Create
4. **Add → Visualization from library** (or Add panel → Library panel) and place a second copy on the board (e.g. under Detail)
5. Confirm both show the same query; edit the library panel once and both update

**Checkpoint:** library panel reused twice.

---

## Step 6 - Polish and export

1. Collapse **Detail** and confirm Overview still refreshes
2. Verify every panel has a **title**, **unit**, and **thresholds** where relevant
3. Save dashboard
4. **Share → Export** → save JSON for Day 3

---

## Done when… (from the deck)

- [ ] Dashboard has two collapsible rows
- [ ] Every panel has a unit and decimals
- [ ] Six panel types are on the board (Time series, Stat, Gauge, Table, Bar gauge, plus Heatmap **or** Geomap - aim for both)
- [ ] One library panel is reused
- [ ] Dashboard saved and JSON exported

---
