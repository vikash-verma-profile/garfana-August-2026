# Day 2 Labs - Data Sources & Dashboard Development

Hands-on labs aligned to **Day-2.pptx** (Modules 5–8).

| Lab | Title | Duration | Folder |
|---|---|---|---|
| **Lab 1** | Observability Stack & Data Sources | ~45–60 min | [lab-1/STEPS.md](lab-1/STEPS.md) |
| **Lab 2** | Service Health Dashboard (Variables & Panels) | ~45–60 min | [lab-2/STEPS.md](lab-2/STEPS.md) |

---

## Day 2 roadmap (from the deck)

1. Working with Data Sources (Prometheus, PostgreSQL, Loki, cloud)
2. Prometheus Integration (scraping, targets, PromQL essentials)
3. Dashboard Creation (design, variables, rows, library panels)
4. Visualization Panels (Stat, Gauge, Time series, Bar gauge, Table)

---

## Suggested order

1. Complete **Lab 1** - stand up Grafana + Prometheus + exporters + PostgreSQL, then add both data sources
2. Complete **Lab 2** - build `Day 2 - Service Health` with variables and five panel types
3. Before Day 3, confirm you can:
   - Open Prometheus Targets and see `node` / `postgres` UP
   - Run `up{job="node"}` in Explore
   - Change the `instance` variable and watch every panel update

---

## Quick start

```bash
cd labs/lab-1
docker compose up -d
# Grafana  http://localhost:3000  →  admin / admin
# Prometheus  http://localhost:9090
```

Then follow [lab-1/STEPS.md](lab-1/STEPS.md).

---

## Default ports (Day 2)

| Port | Service |
|---|---|
| 3000 | Grafana |
| 9090 | Prometheus |
| 9100 | node_exporter |
| 9187 | postgres_exporter |
| 5432 | PostgreSQL (demo DB) |
