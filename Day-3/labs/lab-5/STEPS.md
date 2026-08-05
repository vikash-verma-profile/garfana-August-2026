# Lab 5 - Full Dashboard with Rows, Variables & All Visualizations

**Course:** Grafana Monitoring & Observability - Day 3  
**Module:** Dashboard design gallery (Lab 5)  
**Duration:** ~40–50 minutes  
**Format:** Individual or pairs

---

## Objectives

1. Open a **complete dashboard** with **5 collapsible rows**
2. Use **template variables** (`instance`, `job`, `interval`, `region`) to drive panels
3. Identify and configure **every common visualization type**
4. Change variables and confirm panels update together
5. (Stretch) Duplicate a panel / add your own visualization

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Docker Compose | Builds `demo-api` |
| Ports | **3000**, **9090**, **9100**, **5432**, **8080**, **9187** free |
| Role | Editor or Admin |

Stop overlapping stacks:

```bash
cd ../../Day-2/labs/lab-1
docker compose down
cd ../../Day-3/labs/lab-3
docker compose down
cd ../../Day-3/labs/lab-4
docker compose down
```

Start this lab:

```bash
cd ../../Day-3/labs/lab-5
docker compose up -d --build
docker compose ps
```

Confirm:

- Grafana: http://localhost:3000 - `admin` / `admin`
- Prometheus targets: http://localhost:9090/targets - `node`, `demo-api`, `postgres` **UP**
- demo-api: http://localhost:8080/metrics shows `http_requests_total`

Wait ~30–60s after first start so Prometheus has scraped traffic and Postgres seed data is ready.

---

## Architecture

```
Browser → Grafana :3000
            ├── Prometheus DS → :9090
            │     ← node-exporter :9100
            │     ← postgres-exporter :9187
            │     ← demo-api :8080  (http_requests_total + histogram)
            └── PostgreSQL DS → :5432
                  (orders, api_requests, regions)
```

Dashboard variables sit **above** the panels and rewrite every query that references `$instance`, `$job`, `$interval`, or `$region`.

---

## Visualization map (what you will see)

| Row | Panel | Type | Data |
|---|---|---|---|
| Overview | Target Up | **Stat** | Prometheus `up` |
| Overview | Request Rate | **Stat** | `rate(http_requests_total)` |
| Overview | Memory Available % | **Gauge** | node memory |
| Overview | Disk Used % | **Gauge** | node filesystem |
| Compute | CPU Busy % | **Time series** | node CPU |
| Compute | CPU by Instance | **Bar gauge** | node CPU |
| Compute | Network RX Rate | **Histogram** | node network |
| Traffic | Request Duration | **Heatmap** | demo-api histogram buckets |
| Traffic | Status Codes | **Pie chart** | `http_requests_total` by status |
| Traffic | Requests by Path | **Bar chart** | rate by `path` |
| Business | Top Orders | **Table** | PostgreSQL `orders` |
| Business | Orders by Region | **Geomap** | SQL + lat/lon |
| Status | Target Health | **State timeline** | `up` |
| Status | Jobs | **Status history** | `up` |
| Status | How to use | **Text** | Markdown |

That is **12 visualization types** on one board (Stat through Text).

---

## Lab 5.1 - Open the provisioned dashboard (5 min)

1. Grafana → **Dashboards** → folder **Day 3 - Lab 5**
2. Open **Day 3 Lab 5 - Full Dashboard Gallery**
3. Confirm time range **Last 6 hours**, refresh **30s**
4. Click each row chevron: **Overview**, **Compute**, **Traffic**, **Business Data**, **Status & Notes** — collapse and expand

**Checkpoint:** Five named rows; collapsing one does not break the others.

---

## Lab 5.2 - Template variables (10 min)

At the top of the dashboard you should see:

| Variable | Type | Purpose |
|---|---|---|
| `Instance` | Query (multi + All) | Filters host/instance labels |
| `Job` | Query (multi + All) | Filters Prometheus jobs |
| `Interval` | Interval | Window for `rate(...[$interval])` |
| `Region` | Custom (multi + All) | Filters SQL `orders.region` |

### Exercises

1. Set **Job** to only `demo-api` — Overview **Target Up** / timelines should shrink to that job
2. Set **Job** back to **All**
3. Change **Interval** from `5m` → `1m` — Request Rate / Bar chart should change shape
4. Set **Region** to `eu-west` only — **Table** and **Geomap** should show fewer points
5. Set **Region** back to **All**

**Multi-value rule:** PromQL uses `instance=~"$instance"` and `job=~"$job"` (regex). SQL uses `region IN (${region:sqlstring})` (quoted list). Never use `=` with multi-value variables.

**Checkpoint:** Changing Region updates Table + Geomap; changing Interval updates rate panels.

---

## Lab 5.3 - Walk each visualization (15 min)

Work row by row. For each panel, open the panel menu → **Edit** and note: data source, query, unit, thresholds.

### Overview — Stat & Gauge

- **Stat**: best for “what is the value / state right now” (UP/DOWN, single KPI)
- **Gauge**: same idea with a 0–100 (or min/max) scale and markers

### Compute — Time series, Bar gauge, Histogram

- **Time series**: how a metric changes over the time picker
- **Bar gauge**: compare latest values across series (instances)
- **Histogram**: distribution of values (here: network RX rates across devices)

### Traffic — Heatmap, Pie, Bar chart

- **Heatmap**: latency buckets (`le`) over time from `http_request_duration_seconds_bucket`
- **Pie chart**: share of HTTP status codes (instant query)
- **Bar chart**: categorical compare — request rate by `path`

If Heatmap is empty: wait for more scrapes; confirm demo-api is UP; widen time range.

### Business — Table & Geomap

- **Table**: exact rows from PostgreSQL (currency unit on `amount`)
- **Geomap**: markers from `latitude` / `longitude` / `orders`

If Geomap is blank: check PostgreSQL data source **Save & test**; confirm `regions` table exists:

```bash
docker exec -it postgres psql -U grafana -d demo -c "SELECT * FROM regions;"
```

### Status — State timeline, Status history, Text

- **State timeline**: UP/DOWN bands over time per target
- **Status history**: discrete status cells over time
- **Text**: dashboard documentation in Markdown

**Checkpoint:** You can name each panel type without looking at the title prefix.

---

## Lab 5.4 - Inspect variables in dashboard settings (5 min)

1. Dashboard **Settings** (gear) → **Variables**
2. Open `instance`:
   - Type: Query
   - Query: `label_values(up, instance)`
   - Multi-value: On, Include All: On
3. Open `region`:
   - Type: Custom
   - Values: `us-east,us-west,eu-west,ap-south`
4. Do **not** delete variables — Cancel out or Save if you only viewed them

**Checkpoint:** You understand where variable definitions live vs where panels consume `$name`.

---

## Lab 5.5 - Stretch: add one panel of your own (10 min)

1. In **Compute** row → **Add → Visualization**
2. Pick a type not heavily customized yet (e.g. another **Time series** or **Stat**)
3. Example query:

```promql
sum by (instance) (rate(node_network_transmit_bytes_total{device!~"lo|veth.*", instance=~"$instance"}[$interval]))
```

4. Set title, unit (`Bps`), thresholds
5. **Apply** → **Save dashboard**

Optional: **Share → Export** → save JSON for your notes.

---

## Verification checklist

- [ ] Five rows collapse / expand
- [ ] All four variables visible and change panel data
- [ ] Stat, Gauge, Time series, Bar gauge, Histogram present
- [ ] Heatmap, Pie chart, Bar chart present
- [ ] Table + Geomap show SQL data
- [ ] State timeline + Status history + Text present
- [ ] (Stretch) One extra panel saved

---

## Choosing the right panel (quick card)

| Question | Panel |
|---|---|
| How has it changed over time? | Time series |
| What is the value / state now? | Stat / Gauge |
| How do these items compare? | Bar gauge / Bar chart |
| How is it distributed? | Histogram / Heatmap |
| What is the mix / share? | Pie chart |
| Where is it happening? | Geomap |
| I need exact numbers | Table |
| Did health flip over time? | State timeline / Status history |
| Explain the board | Text |

---

## Files in this lab

| File | Purpose |
|---|---|
| `docker-compose.yml` | Grafana + Prometheus + exporters + Postgres + demo-api |
| `provisioning/dashboards/json/full-dashboard-gallery.json` | Provisioned gallery dashboard |
| `provisioning/datasources/datasources.yml` | Prometheus + PostgreSQL |
| `demo-api/` | Generates HTTP metrics + histogram |
| `postgres/init.sql` | Orders, api_requests, regions seed data |

---

## Cleanup

```bash
docker compose down
# wipe volumes (fresh seed next time):
docker compose down -v
```

---

## Homework

Export this dashboard JSON. Rebuild **one row** from scratch on an empty dashboard using the same variables — without looking at the provisioned JSON.
