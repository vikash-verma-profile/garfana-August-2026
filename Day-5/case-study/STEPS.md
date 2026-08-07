# ShopFront Case Study - Hands-on Steps

**Duration:** ~90–120 minutes  
**Read first:** [CASE-STUDY.md](CASE-STUDY.md) · [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Objectives

1. Run the ShopFront observability stack from Compose
2. Validate Prometheus scrapes and Grafana data sources
3. Use the provisioned **E-Commerce Overview** dashboard to investigate traffic
4. Inject chaos (latency / errors) and watch RED panels move
5. Prove the checkout p95 alert path into MailHog
6. Answer wrap-up questions as a team

---

## Step 0 - Stop conflicting stacks

Free ports **3000, 8080, 9090, 5432, 8025** if other Day labs are running:

```powershell
cd c:\Users\admin\Desktop\grafana\Day-2\labs\lab-1
docker compose down
# repeat for any other running lab folders as needed
```

---

## Step 1 - Start ShopFront

```powershell
cd c:\Users\admin\Desktop\grafana\Day-5\case-study
docker compose up -d --build
docker compose ps
```

Wait until `shopfront-api`, `prometheus`, and `grafana` are Up.

**Health checks:**

```powershell
Invoke-RestMethod http://localhost:8080/health
Invoke-RestMethod http://localhost:3000/api/health
Invoke-RestMethod http://localhost:9090/-/ready
```

---

## Step 2 - Verify Prometheus targets

1. Open http://localhost:9090/targets  
2. Confirm **UP**: `shopfront`, `node`, `postgres`, `prometheus`  
3. In Graph, run:

```promql
up{job="shopfront"}
```

```promql
sum by (route) (rate(http_requests_total[1m]))
```

**Checkpoint:** Live series for `/api/catalog`, `/api/cart`, `/api/checkout`.

---

## Step 3 - Open Grafana & dashboard

1. http://localhost:3000 → `admin` / `admin`  
2. **Connections → Data sources** → Prometheus + PostgreSQL → Save & test (already provisioned)  
3. **Dashboards → ShopFront → E-Commerce Overview**  
4. Set time range **Last 1 hour**, refresh **30s**  
5. Confirm top Stats: rate, error ratio, p95, target UP  

Sketch what you see vs the architecture:

> Shoppers → API → metrics scrape → Prometheus → Grafana panels  
> Orders also land in PostgreSQL → SQL KPI panels

---

## Step 4 - Explore like an on-call (Scenario prep)

**Explore → Prometheus:**

```promql
histogram_quantile(
  0.95,
  sum by (le) (
    rate(http_request_duration_seconds_bucket{route="/api/checkout"}[5m])
  )
)
```

**Explore → PostgreSQL** (Format: Table):

```sql
SELECT status, COUNT(*) AS n, ROUND(SUM(amount)::numeric, 2) AS revenue
FROM orders
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY status
ORDER BY n DESC;
```

**Checkpoint:** You can explain Rate vs Errors vs Duration using the dashboard alone.

---

## Step 5 - Scenario B - Slow checkout (chaos latency)

Inject ~800ms extra latency:

```powershell
Invoke-RestMethod -Method POST -Uri http://localhost:8080/chaos `
  -ContentType "application/json" `
  -Body '{"latency_ms": 800, "error_rate": 0.02}'
```

Or:

```powershell
.\scripts\chaos-latency.ps1
```

Watch for 2–3 minutes:

- Gauge **Checkout p95 latency** crosses the **0.5s** red threshold  
- Time series p95 rises  
- Alert rule `ShopFrontCheckoutP95High` → **Pending** then **Alerting** (evaluation 1m, `for: 2m`)

Open **Alerting → Alert rules** and **MailHog** http://localhost:8025

**Reset chaos:**

```powershell
Invoke-RestMethod -Method POST -Uri http://localhost:8080/chaos `
  -ContentType "application/json" `
  -Body '{"latency_ms": 0, "error_rate": 0.02}'
```

---

## Step 6 - Scenario A - Checkout errors

```powershell
.\scripts\chaos-errors.ps1
# or:
Invoke-RestMethod -Method POST http://localhost:8080/chaos `
  -ContentType "application/json" `
  -Body '{"latency_ms": 0, "error_rate": 0.25}'
```

Observe:

- **Checkout error rate** Stat turns orange/red  
- Bar gauge status mix shows more `500` / `402`  
- Orders `failed` / `declined` climb on the Prometheus orders panel  

Reset when done (`error_rate: 0.02`).

---

## Step 7 - Scenario C - Think scrape failure

Do **not** break the lab for long; discuss:

1. What does `up{job="shopfront"} == 0` mean?  
2. Would you page on No Data for checkout p95, or treat No Data as Alerting?  
3. Which panel on the overview already answers “is the target alive?”

Optional brief drill:

```powershell
docker compose stop shopfront-api
# watch UP → DOWN, then:
docker compose start shopfront-api
```

---

## Step 8 - As-code check (Day 5 habit)

1. Open `grafana/dashboards/ecommerce-overview.json` - find the p95 query  
2. Open `grafana/provisioning/alerting/rules.yml` - confirm threshold `0.5` and labels `team=checkout`  
3. Change a panel title in the JSON, wait ≤30s (or restart Grafana), confirm UI updates  

**Discussion:** If this were production, would `allowUiUpdates: true` still be acceptable?

---

## Step 9 - Team demo (5 minutes)

Present using [ARCHITECTURE.md](ARCHITECTURE.md):

1. Context diagram - who uses Grafana  
2. Container diagram - what Compose runs  
3. Live dashboard - one RED insight + one business KPI  
4. One alert email in MailHog  


## Cleanup

```powershell
docker compose down
# full wipe:
docker compose down -v
```

---

## Files map

| Path | Purpose |
|---|---|
| `app/` | ShopFront API + `/metrics` + `/chaos` |
| `prometheus/prometheus.yml` | Scrape jobs |
| `postgres/init.sql` | Orders schema + seed |
| `grafana/dashboards/` | Overview board |
| `grafana/provisioning/` | DS + dashboard provider + alert |
| `diagrams/*.mmd` | Mermaid sources for export |
| `scripts/` | Chaos helpers |
