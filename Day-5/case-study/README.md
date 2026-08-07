# Case Study - ShopFront E-Commerce Observability

**Course:** Grafana Monitoring & Observability - Day 5 (Final Day)  
**Scenario:** Bring observability to **ShopFront**, a mid-size online retailer  
**Duration:** 90–120 minutes (or take-home)  
**Outcome:** A working stack + dashboards + alerts you can demo

---

## What you will deliver

| Artifact | Location |
|---|---|
| Business & technical brief | [CASE-STUDY.md](CASE-STUDY.md) |
| Architecture diagrams | [ARCHITECTURE.md](ARCHITECTURE.md) · [diagrams/](diagrams/) |
| Hands-on runbook | [STEPS.md](STEPS.md) |
| Runnable lab stack | `docker-compose.yml` + `app/` |
| Provisioned dashboards | `grafana/dashboards/` |
| Alert rule (as code) | `grafana/provisioning/alerting/` |

---

## Quick start

```powershell
cd c:\Users\admin\Desktop\grafana\Day-5\case-study
docker compose up -d --build
```

| Service | URL |
|---|---|
| Grafana | http://localhost:3000 · `admin` / `admin` |
| Prometheus | http://localhost:9090 |
| ShopFront API | http://localhost:8080 |
| ShopFront metrics | http://localhost:8080/metrics |
| MailHog (alert mail) | http://localhost:8025 |

Then open **Dashboards → ShopFront → E-Commerce Overview** and follow [STEPS.md](STEPS.md).

---

## Skills this case study pulls together

| Day | Applied here |
|---|---|
| Day 1 | Grafana UI, Explore, panels |
| Day 2 | Prometheus + PostgreSQL data sources, variables, RED panels |
| Day 3 | PromQL, transformations, Unified Alerting, contact points |
| Day 4 | Folders, teams mindset, provisioning, query hygiene |
| Day 5 | Dashboards/alerts as code, reproducible Compose stack |

---

## Suggested agenda (last training day)

1. **15 min** - Read the brief & architecture together  
2. **20 min** - Bring the stack up; verify targets  
3. **30 min** - Walk the overview dashboard; answer investigation questions  
4. **25 min** - Fire / tune the checkout latency alert  
5. **15 min** - Retro: what would you put in Git before go-live?
