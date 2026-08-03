# Day 3 Labs - Querying, Transformations & Alerting

Hands-on labs aligned to **Day-3.pptx** (Modules 9–12).

| Lab | Title | Duration | Folder |
|---|---|---|---|
| **Lab 1** | Querying in Explore & Query Inspector | ~30–40 min | [lab-1/STEPS.md](lab-1/STEPS.md) |
| **Lab 2** | Panel Transformations | ~25–35 min | [lab-2/STEPS.md](lab-2/STEPS.md) |
| **Lab 3** | Alerting End to End | ~45–60 min | [lab-3/STEPS.md](lab-3/STEPS.md) |

---

## Day 3 roadmap (from the deck)

1. Querying Data (PromQL, SQL, Builder vs Code, Explore, Inspector)
2. Transformations (Merge, Join, Group By, Reduce, Rename, Organize, Filter)
3. Unified Alerting (rules, evaluation, contact points, policies)
4. Notification Channels (Email, Slack, Teams, Webhooks)

---

## Stack dependency

Labs 1–2 reuse the **Day 2** Compose stack:

```bash
cd ../../Day-2/labs/lab-1
docker compose up -d
```

Lab 3 provides its own Compose (adds **MailHog** for SMTP testing). Stop the Day-2 stack first if port 3000 is in use:

```bash
cd ../../Day-2/labs/lab-1
docker compose down
cd ../../Day-3/labs/lab-3
docker compose up -d
```

---

## Suggested order

1. Lab 1 → Lab 2 → Lab 3 (checkpoints must pass before moving on)
2. Before Day 4: one alert rule with `severity` label + `runbook_url` that reaches you
