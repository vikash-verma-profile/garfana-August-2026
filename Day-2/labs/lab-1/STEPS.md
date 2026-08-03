# Lab 1 - Observability Stack & Data Sources

**Course:** Grafana Monitoring & Observability - Day 2  
**Modules:** Working with Data Sources + Prometheus Integration (Hands-on)  
**Duration:** ~45–60 minutes  
**Format:** Work individually or in pairs

---

## Objectives

By the end of this lab you will be able to:

1. Start the Day-2 Docker Compose stack (Grafana, Prometheus, node_exporter, PostgreSQL, postgres_exporter)
2. Verify Prometheus is scraping targets (`UP` in Status → Targets)
3. Add (or confirm) the **Prometheus** data source in Grafana and Save & test
4. Add (or confirm) the **PostgreSQL** data source and Save & test
5. Run first PromQL and SQL checks in **Explore**

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Day 1 complete | Comfortable with Grafana UI, Explore, Docker Compose |
| Ports free | **3000**, **9090**, **9100**, **9187**, **5432** |
| Files | This folder: `labs/lab-1/` |
| Stop Day-1 stack | If Day-1 Grafana is still running: `docker compose down` in Day-1 lab folders |

---

## Architecture (from Day 2 theory)

```
Browser → Grafana :3000
            ├── Prometheus DS  → Prometheus :9090  ← scrape ← node_exporter :9100
            │                                      ← scrape ← postgres_exporter :9187
            └── PostgreSQL DS  → PostgreSQL :5432 (demo DB: orders, api_requests)
```

Grafana queries data sources **at render time**. It does not store Prometheus samples.

---

## Step 1 - Stop conflicting containers

If a Grafana container from Day 1 is still using port 3000 / name `grafana`:

```bash
# From Day-1 lab folder(s)
docker compose down
```

Windows PowerShell example:

```powershell
cd c:\Users\admin\Desktop\grafana\Day-1\labs\lab-1
docker compose down
cd c:\Users\admin\Desktop\grafana\Day-1\labs\lab-2
docker compose down
```

---

## Step 2 - Review the Compose stack

Open `docker-compose.yml`. Services:

| Service | Image / Role |
|---|---|
| `grafana` | UI + provisioning mounts |
| `prometheus` | TSDB, scrapes exporters every 15s |
| `node-exporter` | Host / container CPU, memory, disk metrics |
| `postgres` | Demo DB with seed data (`init.sql`) |
| `postgres-exporter` | Exposes Postgres metrics for Prometheus |

Open `prometheus/prometheus.yml` and confirm scrape jobs: `prometheus`, `node`, `postgres`, `grafana`.

Open `postgres/init.sql` and note tables `orders` and `api_requests` used by SQL panels later.

---

## Step 3 - Bring the stack up

```bash
cd labs/lab-1
```

Windows:

```powershell
cd c:\Users\admin\Desktop\grafana\Day-2\labs\lab-1
```

```bash
docker compose up -d
docker compose ps
```

**Expected:** all five services `Up` (postgres healthy).

Follow Grafana logs briefly:

```bash
docker compose logs -f grafana
```

Press `Ctrl+C` when healthy.

**Troubleshooting:**

| Symptom | Fix |
|---|---|
| Port already allocated | Stop the process using that port, or tell the instructor before editing Compose |
| Postgres never healthy | `docker compose logs postgres` - often a leftover volume with wrong password; `docker compose down -v` then `up -d` |
| Image pull timeout | Check network; retry `docker compose pull` |

---

## Step 4 - Verify Prometheus targets

1. Open [http://localhost:9090](http://localhost:9090)
2. Go to **Status → Targets**
3. Confirm jobs `node`, `postgres`, `prometheus` show state **UP**

Optional PromQL in the Prometheus UI Graph tab:

```promql
up
```

```promql
node_memory_MemAvailable_bytes
```

**Checkpoint:** At least `node` and `postgres` are UP. If DOWN, check `docker compose ps` and the **Error** column on the Targets page.

---

## Step 5 - First login to Grafana

1. Open [http://localhost:3000](http://localhost:3000)
2. Login: `admin` / `admin` (change password if prompted - training may keep it simple)

Optional health check:

```powershell
Invoke-RestMethod http://localhost:3000/api/health
```

---

## Step 6 - Configure Prometheus data source (UI walkthrough)

This folder also **provisions** Prometheus automatically. Still perform the UI path once so you practice Module 5 skills.

### If already provisioned

1. **Connections → Data sources → Prometheus**
2. Confirm URL `http://prometheus:9090`
3. Click **Save & test**
4. Expect: *Successfully queried the Prometheus API* (wording varies)

### If adding manually

1. **Connections → Data sources → Add data source → Prometheus**
2. **URL:** `http://prometheus:9090`  
   > Use the **Docker service name** `prometheus`, not `localhost`, when Grafana runs inside Compose.
3. **Scrape interval / HTTP method:** 15s / POST (optional)
4. **Save & test**

**Checkpoint (deck task 1):** Prometheus API queried successfully.

---

## Step 7 - Configure PostgreSQL data source

### If already provisioned

1. Open **PostgreSQL** data source
2. Confirm Host `postgres:5432`, Database `demo`, User `grafana`, TLS/SSL **disable**
3. **Save & test** → database connection OK

### If adding manually

| Field | Value |
|---|---|
| Host | `postgres:5432` |
| Database | `demo` |
| User | `grafana` |
| Password | `grafana` |
| TLS/SSL Mode | `disable` |

**Checkpoint (deck task 2):** Database connection OK.

> Production reminder from the deck: always use a **read-only** DB user and require TLS.

---

## Step 8 - Smoke-test both sources in Explore

### Prometheus

1. Open **Explore**
2. Data source: **Prometheus**
3. Run:

```promql
up{job="node"}
```

4. Switch to range view if needed; time range **Last 15 minutes**
5. Also try:

```promql
rate(node_cpu_seconds_total{mode="idle"}[5m])
```

### PostgreSQL

1. Stay in Explore; switch data source to **PostgreSQL**
2. Format as **Table**
3. Run:

```sql
SELECT status, COUNT(*) AS orders
FROM orders
GROUP BY status
ORDER BY orders DESC;
```

4. Then a time-series oriented query:

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

**Checkpoint:** Both Explore queries return data without errors.

---

## Step 9 - Cardinality & scrape hygiene (theory drill)

Answer briefly (use Targets + Explore as evidence):

1. What does `up{job="node"} == 0` tell you?
2. Why wrap counters in `rate()` instead of graphing raw counters?
3. Why must Grafana use `http://prometheus:9090` inside Docker, not `localhost:9090`?

---

## Success criteria checklist

- [ ] `docker compose ps` shows grafana, prometheus, node-exporter, postgres, postgres-exporter Up
- [ ] Prometheus Targets: `node` and `postgres` are UP
- [ ] Prometheus data source Save & test succeeds
- [ ] PostgreSQL data source Save & test succeeds
- [ ] Explore returns series for `up{job="node"}`
- [ ] Explore SQL against `orders` returns rows

---

## Files in this lab

| File | Purpose |
|---|---|
| `docker-compose.yml` | Full Day-2 stack |
| `prometheus/prometheus.yml` | Scrape configs |
| `postgres/init.sql` | Demo tables + seed data |
| `provisioning/datasources/datasources.yml` | Optional auto-provision of both DSs |

---

## Cleanup / handoff

Keep the stack running for Lab 2:

```bash
docker compose ps
```

Full reset:

```bash
docker compose down -v
```

---

## Next lab

Continue with **[Lab 2 - Service Health Dashboard](../lab-2/STEPS.md)** using this same running stack.
