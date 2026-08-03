# Day 1 LabsGrafana Fundamentals & Environment Setup

Hands-on labs aligned to **Grafana Fundamentals.pptx** (Day 1).

| Lab | Title | Duration | Folder |
|---|---|---|---|
| **Lab 1** | Stand Up Grafana with Docker Compose | ~45 min | [lab-1/STEPS.md](lab-1/STEPS.md) |
| **Lab 2** | Grafana UI Walkthrough & Administration | ~45–60 min | [lab-2/STEPS.md](lab-2/STEPS.md) |

---

## Day 1 roadmap (from the deck)

1. Monitoring & Observability (metrics, logs, traces)
2. Grafana Architecture (frontend, backend, data sources, panels)
3. Installation & Configuration (Docker / Linux / Windows)
4. Grafana UI Walkthrough
5. Hands-on labs (this folder)

---

## Suggested order

1. Complete **Lab 1**get Grafana running with Docker Compose  
2. Complete **Lab 2**UI tour, Explore, first dashboard, admin basics  
3. Before Day 2, confirm you can:
   - Start/stop the Grafana container on demand
   - Log in and open **Explore**
   - Name the three pillars of observability
   - Say where Grafana stores config vs persistent data in Docker

---

## Quick start

```bash
cd labs/lab-1
docker compose up -d
# Open http://localhost:3000  →  admin / admin
```

Then follow [lab-1/STEPS.md](lab-1/STEPS.md).

---

## Default ports (Day 1 reference)

| Port | Service |
|---|---|
| 3000 | Grafana |
| 9090 | Prometheus (Day 2+) |
| 3100 | Loki |
| 9100 | node_exporter |
