# Lab 4 - Insert Custom Values & View Custom Metrics in Grafana

**Course:** Grafana Monitoring & Observability - Day 3  
**Module:** Custom application metrics (Lab 4)  
**Duration:** ~30–40 minutes  
**Format:** Individual or pairs

---

## Objectives

1. Create a **custom metric** (gauge or counter) via the lab API
2. **Insert / update** custom values and see them scraped by Prometheus
3. Query the metric in Grafana **Explore** and on a provisioned **dashboard**
4. (Optional) Push a one-shot value through **Pushgateway** (batch-job pattern)

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Docker Compose | Builds `custom-metrics` image |
| Ports | **3000**, **9090**, **8081**, **9091** free |
| Role | Editor or Admin in Grafana |

Stop other stacks if needed:

```bash
cd ../../Day-2/labs/lab-1
docker compose down
cd ../../Day-3/labs/lab-3
docker compose down
```

Start this lab:

```bash
cd ../../Day-3/labs/lab-4
docker compose up -d --build
docker compose ps
```

Confirm:

- Grafana: http://localhost:3000 - `admin` / `admin`
- Custom API: http://localhost:8081/health → `{"status": "ok"}`
- Prometheus targets: http://localhost:9090/targets - `custom-metrics` and `pushgateway` **UP**

---

## Architecture

```
You (curl / scripts)
   ├── POST /api/metrics  →  custom-metrics :8081  →  GET /metrics
   └── POST Pushgateway   →  pushgateway :9091
                                    ↓
                           Prometheus scrapes (:9090)
                                    ↓
                           Grafana Explore / Dashboard (:3000)
```

| Path | When to use |
|---|---|
| **custom-metrics API** | Long-lived app metrics you create and update |
| **Pushgateway** | Short-lived / batch jobs that push a value then exit |

---

## Lab 4.1 - Inspect seeded custom metrics (5 min)

The API starts with two demo metrics.

1. Open http://localhost:8081/metrics - confirm Prometheus text format
2. Open http://localhost:8081/api/metrics - JSON list of registered series
3. In Prometheus UI → Graph, run:

```promql
lab_demo_temperature_celsius
```

and

```promql
lab_demo_orders_total
```

4. Grafana → **Explore** → Prometheus → same queries → **Run query**

**Checkpoint:** Both series appear in Explore (Last 15 minutes).

---

## Lab 4.2 - Create a custom metric and insert a value (10 min)

### Option A - PowerShell helper

```powershell
cd lab-4
.\scripts\set-metric.ps1 -Name lab_queue_depth -Value 42 -Labels @{region="us"; env="lab"}
```

Update the value:

```powershell
.\scripts\set-metric.ps1 -Name lab_queue_depth -Value 7 -Labels @{region="us"; env="lab"}
```

### Option B - curl (any shell)

```bash
curl -sS -X POST http://localhost:8081/api/metrics \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"lab_queue_depth\",\"type\":\"gauge\",\"value\":42,\"labels\":{\"region\":\"us\",\"env\":\"lab\"}}"
```

Quick set via query string:

```bash
curl "http://localhost:8081/set?name=lab_queue_depth&value=7&type=gauge&region=us&env=lab"
```

### Option C - counter (must not decrease)

```powershell
.\scripts\set-metric.ps1 -Name lab_checkouts_total -Value 10 -Type counter -Labels @{region="lab"}
.\scripts\set-metric.ps1 -Name lab_checkouts_total -Value 15 -Type counter -Labels @{region="lab"}
```

Verify on the wire:

```bash
curl -sS http://localhost:8081/metrics | findstr lab_
```

**Checkpoint:** `lab_queue_depth` (and optional counter) show in `/metrics` with your labels.

---

## Lab 4.3 - Confirm scrape → Prometheus → Grafana (10 min)

Prometheus scrapes every **10s**. Wait one scrape cycle, then:

1. http://localhost:9090/targets - `custom-metrics` **UP**
2. Prometheus Graph:

```promql
lab_queue_depth
```

or with labels:

```promql
lab_queue_depth{region="us"}
```

3. Grafana → **Explore** → run the same PromQL
4. Change the value again with the script / curl, wait ~10–20s, confirm the graph steps to the new value

**Checkpoint:** Explore time series updates after you insert a new value.

---

## Lab 4.4 - View on the provisioned dashboard (5 min)

1. Grafana → **Dashboards** → folder **Day 3 - Lab 4**
2. Open **Day 3 Lab 4 - Custom Metrics**
3. Confirm:
   - Temperature / Orders stats (seeded metrics)
   - `custom-metrics UP` = 1
   - Time series panel shows `lab_*` metrics (including yours)
4. Insert another value for `lab_queue_depth` and watch the panel refresh (dashboard refresh is **10s**)

Optional: **Add panel** → query your metric → Stat or Time series → Save dashboard.

**Checkpoint:** Your custom metric is visible on the dashboard without querying Explore.

---

## Lab 4.5 - Pushgateway: push a one-shot custom value (optional, 10 min)

Batch jobs often cannot be scraped. They **push** to Pushgateway instead.

### PowerShell

```powershell
.\scripts\push-metric.ps1 -Name lab_batch_duration_seconds -Value 3.14 -Instance student1
```

### curl

```bash
cat <<'EOF' | curl --data-binary @- http://localhost:9091/metrics/job/lab4/instance/student1
# TYPE lab_batch_duration_seconds gauge
# HELP lab_batch_duration_seconds Duration of a demo batch job
lab_batch_duration_seconds 3.14
EOF
```

Then in Explore:

```promql
lab_batch_duration_seconds{job="lab4"}
```

or

```promql
{job="lab4"}
```

Pushgateway UI: http://localhost:9091 - confirm the group `job/lab4`.

**Checkpoint:** Pushed series appears in Prometheus/Grafana and on the dashboard panel **Pushgateway pushes**.

---

## Verification checklist

- [ ] `custom-metrics` and `pushgateway` targets are UP
- [ ] Seeded metrics visible in Explore
- [ ] Created `lab_queue_depth` (or your own name) with a custom value
- [ ] Updated the value and saw Grafana refresh
- [ ] Provisioned dashboard shows `lab_*` series
- [ ] (Optional) Pushgateway push visible with `job="lab4"`

---

## Metric hygiene (from wrap-up)

| Do | Don't |
|---|---|
| Prefix lab/app metrics (`lab_`, `app_`) | Reuse reserved names (`up`, `process_*`) |
| Use **gauge** for levels that go up/down | Decrease a **counter** |
| Add low-cardinality labels (`region`, `env`) | High-cardinality labels (user id, request id) |
| Prefer a real `/metrics` exporter for services | Use Pushgateway for long-lived services |

---

## Files in this lab

| File | Purpose |
|---|---|
| `docker-compose.yml` | Grafana + Prometheus + custom-metrics + Pushgateway |
| `custom-metrics/` | Small API to create metrics and insert values |
| `prometheus/prometheus.yml` | Scrapes custom-metrics + Pushgateway |
| `provisioning/` | Prometheus DS + provisioned dashboard |
| `scripts/set-metric.ps1` / `.sh` | Insert values into the API |
| `scripts/push-metric.ps1` / `.sh` | Push values to Pushgateway |

---

## Cleanup

```bash
docker compose down
# wipe Grafana/Prometheus data:
docker compose down -v
```

---

## Homework

Create one real custom metric for something you care about (queue depth, feature flag users, batch duration). Push or export it, and add a Grafana panel with a clear title and unit.
