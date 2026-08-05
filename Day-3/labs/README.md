# Day 3 Labs - Querying, Transformations & Alerting

Hands-on labs aligned to **Day-3.pptx** (Modules 9–12).

| Lab | Title | Duration | Folder |
|---|---|---|---|
| **Lab 1** | Querying in Explore & Query Inspector | ~30–40 min | [lab-1/STEPS.md](lab-1/STEPS.md) |
| **Lab 2** | Panel Transformations | ~25–35 min | [lab-2/STEPS.md](lab-2/STEPS.md) |
| **Lab 3** | Alerting End to End | ~45–60 min | [lab-3/STEPS.md](lab-3/STEPS.md) |
| **Lab 4** | Custom Metrics (create, insert, view) | ~30–40 min | [lab-4/STEPS.md](lab-4/STEPS.md) |
| **Lab 5** | Full Dashboard Gallery (rows, vars, all viz) | ~40–50 min | [lab-5/STEPS.md](lab-5/STEPS.md) |

---

## Day 3 roadmap (from the deck)

1. Querying Data (PromQL, SQL, Builder vs Code, Explore, Inspector)
2. Transformations (Merge, Join, Group By, Reduce, Rename, Organize, Filter)
3. Unified Alerting (rules, evaluation, contact points, policies)
4. Notification Channels (Email, Slack, Teams, Webhooks)
5. Custom Metrics (create gauges/counters, insert values, view in Grafana)
6. Full Dashboard Design (rows, variables, visualization gallery)

---

## Stack dependency

Labs 1–2 reuse the **Day 2** Compose stack:

```bash
cd ../../Day-2/labs/lab-1
docker compose up -d
```

Lab 3 provides its own Compose (adds **MailHog** for SMTP testing). Lab 4 provides its own Compose (custom-metrics API + Pushgateway). Lab 5 provides its own Compose (full gallery: Prometheus + Postgres + demo-api). Stop the Day-2 stack first if port 3000 is in use:

```bash
cd ../../Day-2/labs/lab-1
docker compose down
cd ../../Day-3/labs/lab-3
docker compose up -d
```

For Lab 4 (stop Lab 3 first if ports overlap):

```bash
cd ../../Day-3/labs/lab-3
docker compose down
cd ../../Day-3/labs/lab-4
docker compose up -d --build
```

For Lab 5 (stop Lab 4 first if ports overlap):

```bash
cd ../../Day-3/labs/lab-4
docker compose down
cd ../../Day-3/labs/lab-5
docker compose up -d --build
```

---

## Suggested order

1. Lab 1 → Lab 2 → Lab 3 → Lab 4 → Lab 5 (checkpoints must pass before moving on)
2. Before Day 4: one alert rule with `severity` label + `runbook_url` that reaches you; one custom metric panel; and a dashboard export that uses variables + rows
