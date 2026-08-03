# Lab 1 - Querying in Explore & Query Inspector

**Course:** Grafana Monitoring & Observability - Day 3  
**Module:** Querying Data (Guided Practice 9)  
**Duration:** ~30–40 minutes  
**Depends on:** Day-2 Lab 1 stack (Grafana + Prometheus)

---

## Objectives

1. Run and refine PromQL in Explore (Builder and Code modes)
2. Use aggregations (`sum by`, `topk`)
3. Inspect the exact request/response with **Query Inspector**
4. Add a finished query to a dashboard panel

---

## Prerequisites

```bash
cd ../../Day-2/labs/lab-1
docker compose up -d
docker compose ps
```

Open [http://localhost:3000](http://localhost:3000) - confirm Prometheus data source works in Explore.

If targets are down, open [http://localhost:9090/targets](http://localhost:9090/targets).

---

## Query architecture reminder

```
Panel / Explore → Data source plugin → Backend (PromQL/SQL)
                → Data frames → Transform (optional) → Visualize
```

Every query is scoped by the **time picker** and template variables.

---

## Step 1 - Open Explore on Prometheus

1. Nav → **Explore**
2. Data source: **Prometheus**
3. Time range: **Last 15 minutes** (widen to 6h if empty)
4. Prefer **Code** mode for this lab (switch Builder ↔ Code later)

---

## Step 2 - Baseline CPU rate

Run:

```promql
rate(node_cpu_seconds_total{mode="user"}[5m])
```

Observe many series (one per CPU mode/cpu label set).

**If No data:** widen to Last 6 hours; confirm `node` job is UP in Prometheus.

---

## Step 3 - Aggregate by instance

Wrap with `sum by (instance)`:

```promql
sum by (instance) (
  rate(node_cpu_seconds_total{mode="user"}[5m])
)
```

Compare the graph to Step 2 - fewer series, clearer story.

Optional memory ratio:

```promql
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
```

CPU busy % (deck example):

```promql
100 - avg by (instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
) * 100
```

---

## Step 4 - Builder ↔ Code round-trip

1. Switch to **Builder** mode
2. Confirm metric / labels / functions still match
3. Switch back to **Code**
4. Confirm the query text survived

---

## Step 5 - Keep only the busiest three

```promql
topk(3, sum by (instance) (
  rate(node_cpu_seconds_total{mode="user"}[5m])
))
```

Note: `topk` on a range graph can look “jumpy”; that is expected for teaching.

---

## Step 6 - Query Inspector

1. Open **Query Inspector** (inspector icon / Query tab)
2. Review tabs:
   - **Data** - returned frames; download CSV
   - **Stats** - request time, rows
   - **Query** - raw request URL/body and response
3. Download CSV from Data
4. Confirm you can point to the exact request Grafana sent

**“No data” debug order (from the deck):**

1. Time range wrong?
2. Same query works in Explore?
3. Inspector → Data empty or null?
4. Variables interpolated correctly?
5. Stats showing timeout?
6. Format as / field mapping mismatch?

---

## Step 7 - Add to dashboard

1. Click **Add to dashboard**
2. New dashboard (or existing Training folder board)
3. Panel title: `CPU by instance`
4. Save as `Day3 Query Practice` in folder `Training`

---

## SQL stretch (optional)

Switch Explore to **PostgreSQL** and run:

```sql
SELECT
  $__timeGroup(created_at, $__interval) AS time,
  status_code AS metric,
  COUNT(*) AS value
FROM api_requests
WHERE $__timeFilter(created_at)
GROUP BY 1, 2
ORDER BY 1;
```

Then table format:

```sql
SELECT endpoint,
       AVG(duration_ms) AS avg_ms,
       COUNT(*) AS calls
FROM api_requests
WHERE $__timeFilter(created_at)
GROUP BY endpoint
ORDER BY avg_ms DESC
LIMIT 10;
```

---

## Success criteria

- [ ] Ran `rate(...{mode="user"}[5m])` in Explore
- [ ] Compared raw vs `sum by (instance)` graphs
- [ ] Builder ↔ Code round-trip worked
- [ ] Used `topk(3, ...)`
- [ ] Downloaded Inspector CSV and found the raw query request
- [ ] Saved panel `CPU by instance` on a dashboard

---

## Next lab

**[Lab 2 - Panel Transformations](../lab-2/STEPS.md)**
