# Lab 1 - Data Sources (Prometheus, PostgreSQL, Loki)

**Course:** Grafana Monitoring & Observability - Day 2  
**Modules:** Working with Data Sources + Prometheus Integration  
**Source:** Day-2.pptx - Hands-on Lab 1 (slides 12–13)  
**Duration:** ~30–45 minutes  
**Format:** Work individually or in pairs

---

## Objectives

By the end of this lab you will be able to:

1. Start the Day-2 Docker Compose stack (Grafana, Prometheus, node_exporter, PostgreSQL, postgres_exporter, Loki, Promtail, demo-api)
2. Add **Prometheus**, **PostgreSQL**, and **Loki** data sources and get Save & test green
3. Verify Prometheus targets (`node` UP) in the Prometheus UI
4. Run a SQL table query against `orders`
5. Run LogQL `{job="node"}` and a PromQL range query for `http_requests_total`

---

## Prerequisites


| Requirement      | Notes                                                                         |
| ---------------- | ----------------------------------------------------------------------------- |
| Day 1 complete   | Comfortable with Grafana UI, Explore, Docker Compose                          |
| Docker Desktop   | Running (Windows/macOS/Linux)                                                 |
| Ports free       | **3000**, **9090**, **9100**, **9187**, **5432**, **3100**, **8080**          |
| Files            | This folder: `labs/lab-1/`                                                    |
| Stop Day-1 stack | If Day-1 Grafana is still running: `docker compose down` in Day-1 lab folders |


---

## Architecture (from Day 2 theory)

```
Browser → Grafana :3000
            ├── Prometheus DS  → Prometheus :9090
            │                      ← scrape ← node_exporter :9100
            │                      ← scrape ← postgres_exporter :9187
            │                      ← scrape ← demo-api :8080  (http_requests_total)
            ├── PostgreSQL DS  → PostgreSQL :5432 (db: demo)
            └── Loki DS        → Loki :3100 ← Promtail ← demo-api / node logs (job=node)
```

Grafana queries data sources **at render time**. It does not store Prometheus samples or Loki log lines.

---

## Step 1 - Stop conflicting containers

```powershell
# Day-1 examples (adjust paths if needed)
cd c:\Users\admin\Desktop\grafana\Day-1\labs\lab-1
docker compose down
cd c:\Users\admin\Desktop\grafana\Day-1\labs\lab-2
docker compose down
```

---

## Step 2 - Review the Compose stack

Open `docker-compose.yml`. Services:


| Service             | Role                                          |
| ------------------- | --------------------------------------------- |
| `grafana`           | UI + optional provisioning                    |
| `prometheus`        | TSDB, scrapes exporters every 15s             |
| `node-exporter`     | Host / container CPU, memory, disk metrics    |
| `postgres`          | Demo DB (`orders`, `api_requests`, `regions`) |
| `postgres-exporter` | Postgres metrics for Prometheus               |
| `demo-api`          | Exposes `http_requests_total` + JSON logs     |
| `loki`              | Log store                                     |
| `promtail`          | Ships container logs to Loki with `job=node`  |


Open `prometheus/prometheus.yml` and confirm scrape jobs: `prometheus`, `node`, `postgres`, `grafana`, `demo-api`.

---

## Step 3 - Bring the stack up

```powershell
cd c:\Users\admin\Desktop\grafana\Day-2\labs\lab-1
docker compose up -d --build
docker compose ps
```

**Expected:** all services `Up` (postgres healthy). First build of `demo-api` may take a minute.

```powershell
docker compose logs -f grafana
```

Press `Ctrl+C` when healthy.


| Symptom                                | Fix                                                                                                                                   |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Port already allocated                 | Stop the process using that port, or tell the instructor before editing Compose                                                       |
| Postgres never healthy                 | `docker compose logs postgres` - leftover volume: `docker compose down -v` then `up -d --build`                                       |
| Missing `regions` table (Lab 3 Geomap) | Existing volume skipped `init.sql`. Run: `Get-Content postgres\migrate-regions.sql | docker exec -i postgres psql -U grafana -d demo` |
| demo-api build fails                   | Check Docker Desktop is running; retry `docker compose build demo-api`                                                                |
| Loki / Promtail unhealthy              | `docker compose logs loki promtail`                                                                                                   |
| Prometheus missing `demo-api` target   | After editing `prometheus.yml` on a running stack: `Invoke-WebRequest -Method Post http://localhost:9090/-/reload`                    |


---

## Step 4 - Task 1: Add Prometheus data source

> Deck checkpoint: Save & test returns green

This folder also **provisions** Prometheus automatically. Still perform the UI path once.

1. Open [http://localhost:3000](http://localhost:3000) - login `admin` / `admin`
2. **Connections → Data sources → Add data source → Prometheus**
  (or open the existing **Prometheus** entry if already listed)
3. Set:


| Field           | Value                    |
| --------------- | ------------------------ |
| URL             | `http://prometheus:9090` |
| Scrape interval | `15s`                    |


1. Click **Save & test**

> Use the Docker **service name** `prometheus`, not `localhost`, when Grafana runs inside Compose.

**Checkpoint:** message like *Successfully queried the Prometheus API*.

---

## Step 5 - Task 2: Inspect Prometheus targets

> Deck checkpoint: node exporter target is UP

1. Open [http://localhost:9090](http://localhost:9090)
2. Go to **Status → Targets**
3. Read `job` and `instance` labels
4. Note last scrape duration and any **DOWN** targets

Confirm at least:


| Job        | Expected |
| ---------- | -------- |
| `node`     | **UP**   |
| `demo-api` | **UP**   |
| `postgres` | **UP**   |


Optional PromQL in the Prometheus Graph tab:

```promql
up
```

**Checkpoint:** `node` is UP. If DOWN, check `docker compose ps` and the Error column on Targets.

---

## Step 6 - Task 3: Add PostgreSQL data source

> Deck checkpoint: table panel / Explore returns rows


| Field        | Value           |
| ------------ | --------------- |
| Host         | `postgres:5432` |
| Database     | `demo`          |
| User         | `grafana`       |
| Password     | `grafana`       |
| TLS/SSL Mode | `disable`       |


> The deck sometimes shows `db:5432` / `appdb`. This lab stack uses `**postgres:5432**` / `**demo**` (same as the Lab 2 environment slide).

1. **Connections → Data sources → Add → PostgreSQL** (or open provisioned entry)
2. Fill the table above → **Save & test**
3. Open **Explore** → data source **PostgreSQL** → Format as **Table**:

```sql
SELECT status, COUNT(*) AS orders
FROM orders
GROUP BY status
ORDER BY orders DESC;
```

**Checkpoint:** rows return (pending / paid / shipped / cancelled).

Production reminder from the deck: always use a **read-only** DB user and require TLS.

---

## Step 7 - Task 4: Add Loki data source

> Deck checkpoint: logs render for `{job="node"}`

1. **Connections → Data sources → Add → Loki** (or open provisioned entry)
2. **URL:** `http://loki:3100`
3. **Save & test**
4. Open **Explore** → data source **Loki**
5. Run LogQL:

```logql
{job="node"}
```

Optional filters:

```logql
{job="node"} |= "error"
```

```logql
{job="node"} | json | level="error"
```

Wait ~30–60s after stack start if no lines yet (Promtail + self-traffic need a moment).

**Checkpoint:** log lines render for `job="node"`.

---

## Step 8 - Task 5: Query time series (instant vs range)

> Deck checkpoint: range query graphs multiple series

1. **Explore** → data source **Prometheus**
2. Run:

```promql
rate(http_requests_total[5m])
```

1. Toggle **Instant** vs **Range** (Range draws a line over time; Instant is one value per series - use Instant for Stat/Gauge later)
2. Group:

```promql
sum by (instance) (rate(http_requests_total[5m]))
```

Also try status grouping:

```promql
sum by (status) (rate(http_requests_total[5m]))
```

Time range: **Last 15 minutes**.

Generate extra traffic if you want:

```powershell
1..20 | ForEach-Object { Invoke-WebRequest http://localhost:8080/api -UseBasicParsing | Out-Null }
```

**Checkpoint:** range query graphs series (multiple status/path combinations or grouped by instance).

---

## Step 9 - Optional: one dashboard with metrics + logs

1. **Dashboards → New → New dashboard**
2. Add a **Time series** panel with `rate(http_requests_total[5m])`
3. Add a **Logs** panel with `{job="node"}`
4. Save as `Day 2 - Metrics and Logs` in folder `Training` (create folder if needed)

This satisfies the deck “Done when… One dashboard queries metrics and logs”.

---

## Success criteria checklist (from the deck)

- [ ] All three data sources Save & test green (Prometheus, PostgreSQL, Loki)
- [ ] Targets page shows jobs UP (`node` required; prefer all UP)
- [ ] SQL on `orders` returns rows
- [ ] `{job="node"}` returns logs
- [ ] Range query on `http_requests_total` returns series
- [ ] Data source names noted for Labs 2–3 (`Prometheus`, `PostgreSQL`, `Loki`)

---

## Files in this lab


| File                                       | Purpose                                             |
| ------------------------------------------ | --------------------------------------------------- |
| `docker-compose.yml`                       | Full Day-2 stack                                    |
| `prometheus/prometheus.yml`                | Scrape configs                                      |
| `postgres/init.sql`                        | Demo tables + seed data (first boot)                |
| `postgres/migrate-regions.sql`             | Add `regions` / `orders.region` on existing volumes |
| `loki/loki-config.yml`                     | Single-node Loki                                    |
| `promtail/promtail-config.yml`             | Ships demo-api logs as `job=node`                   |
| `demo-api/`                                | Tiny HTTP app + `/metrics` (`http_requests_total`)  |
| `provisioning/datasources/datasources.yml` | Optional auto-provision of all three DSs            |


---

## Cleanup / handoff

**Keep the stack running** for Lab 2 and Lab 3:

```powershell
docker compose ps
```

Full reset:

```powershell
docker compose down -v
```

---

## Next lab

Continue with **[Lab 2 - Service Health Dashboard](../lab-2/STEPS.md)** using this same running stack.