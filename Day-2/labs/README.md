# Day 2 Labs — Data Sources & Dashboard Development

Hands-on labs aligned to **Day-2.pptx** (Modules 5–8).

| Lab | Title | Duration | Folder |
|---|---|---|---|
| **Lab 1** | Data Sources (Prometheus, PostgreSQL, Loki) | ~30–45 min | [lab-1/STEPS.md](lab-1/STEPS.md) |
| **Lab 2** | Service Health Dashboard (Variables & Panels) | ~30–45 min | [lab-2/STEPS.md](lab-2/STEPS.md) |
| **Lab 3** | Host Health Visualizations (Gallery + Library) | ~30–45 min | [lab-3/STEPS.md](lab-3/STEPS.md) |

---

## Day 2 roadmap (from the deck)

1. Working with Data Sources (Prometheus, PostgreSQL, Loki, cloud)
2. Prometheus Integration (scraping, targets, PromQL essentials)
3. Dashboard Creation (design, variables, rows, library panels)
4. Visualization Panels (Stat, Gauge, Time series, Bar gauge, Table, Heatmap, Geomap)

Four cycles: teach → check → build (~55 minutes each).

---

## Suggested order

1. **Lab 1** — stand up the stack; wire Prometheus, PostgreSQL, Loki; prove each returns data  
2. **Lab 2** — build `Day 2 - Service Health` with variables and five panel types  
3. **Lab 3** — build `Host Health` with six+ panel types and a library panel  
4. Before Day 3, confirm you can:
   - Open Prometheus Targets and see `node` / `demo-api` UP  
   - Run `{job="node"}` in Explore (Loki)  
   - Change the `instance` variable and watch panels update  
   - Export dashboard JSON  

---

## Quick start

```powershell
cd c:\Users\admin\Desktop\grafana\Day-2\labs\lab-1
docker compose up -d --build
# Grafana     http://localhost:3000  →  admin / admin
# Prometheus  http://localhost:9090
# Loki        http://localhost:3100
# demo-api    http://localhost:8080
```

Then follow [lab-1/STEPS.md](lab-1/STEPS.md).

Labs 2 and 3 reuse the **same** Lab 1 stack — do not start a second Compose unless you stop Lab 1 first.

---

## Default ports (Day 2)

| Port | Service |
|---|---|
| 3000 | Grafana |
| 9090 | Prometheus |
| 9100 | node_exporter |
| 9187 | postgres_exporter |
| 5432 | PostgreSQL (demo DB) |
| 3100 | Loki |
| 8080 | demo-api (`http_requests_total`) |

---

## Stack diagram

```
Browser → Grafana :3000
            ├── Prometheus DS → :9090 ← node_exporter, postgres_exporter, demo-api
            ├── PostgreSQL DS → :5432 (orders, api_requests, regions)
            └── Loki DS       → :3100 ← Promtail (job=node)
```
