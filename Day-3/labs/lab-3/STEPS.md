# Lab 3 - Alerting End to End

**Course:** Grafana Monitoring & Observability - Day 3  
**Modules:** Alerting + Notification Channels (Lab 3.1–3.4)  
**Duration:** ~45–60 minutes  
**Format:** Pairs recommended

---

## Objectives

1. Create alert rule `HighCpuUsage` with query → reduce → threshold
2. Configure **Email** contact point via MailHog SMTP
3. Configure **Slack** contact point (webhook) + child notification policy for `severity=critical`
4. Force the rule to fire, verify email/Slack, silence, and resolve

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Grafana 10+ | Unified Alerting enabled (default in this Compose) |
| Ports | 3000, 9090, 9100, **1025**, **8025** |
| Slack | Workspace where you may add an Incoming Webhook (or skip Slack and use webhook.site) |
| Role | Editor or Admin |

Stop Day-2 stack if needed:

```bash
cd ../../Day-2/labs/lab-1
docker compose down
```

Start this lab:

```bash
cd ../../Day-3/labs/lab-3
docker compose up -d
docker compose ps
```

Confirm:

- Grafana: http://localhost:3000 - `admin` / `admin`
- MailHog: http://localhost:8025
- Prometheus targets: http://localhost:9090/targets - `node` UP

---

## Architecture

```
Alert rule (PromQL) → Evaluation (1m, pending 2m)
        → Grafana Alertmanager
        → Notification policies (matchers)
              ├── default → ops-email → MailHog
              └── severity=critical → slack-oncall → Slack webhook
```

---

## Lab 3.1 - Create alert rule (10 min)

1. **Alerting → Alert rules → New alert rule**
2. Name: `HighCpuUsage`
3. **Query A** - Prometheus:

```promql
100 - avg by (instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
) * 100
```

4. **Expression B:** Reduce → **Last** (input A)
5. **Expression C:** Threshold → **B > 80**  
   Mark **C** as the alert condition  
   > Can't reach 80% on a quiet lab host? Use **B > 5** (or even `> 0.1`) so it fires during class.
6. Click **Preview** - expect one row per instance
7. Folder: `Training` (create if needed)
8. Evaluation group: `day3` - interval **1m**
9. Pending period: **2m** (fires quickly for the demo)
10. Labels:
    - `severity` = `critical`
    - `team` = `platform`
11. Annotations:
    - `summary` = `CPU above threshold for instance`
    - `runbook_url` = `https://example.com/runbooks/high-cpu`
12. **Save rule and exit**

**Checkpoint:** Rule appears under Alert rules with state **Normal** (until load); Preview showed instances.

---

## Lab 3.2 - Configure email alerts (10 min)

SMTP is already set in `grafana/grafana.ini` → MailHog (`mailhog:1025`).

1. **Alerting → Contact points → Add contact point**
2. Name: `ops-email`
3. Integration: **Email**
4. Addresses: your address (any mailbox string works with MailHog), e.g. `oncall@lab.local`
5. Leave **single email** off
6. Optional subject template:

```
[{{ .Status }}] {{ .CommonLabels.alertname }}
```

7. **Test → Send test notification**
8. Open MailHog UI: http://localhost:8025 - confirm the test message
9. **Notification policies →** edit **Default policy**
10. Contact point: `ops-email` → Save

**Checkpoint:** Test email visible in MailHog with alert name in the subject.

**Nothing arrives?** Administration → Settings / check Compose logs; confirm `[smtp] enabled` loaded (`docker compose logs grafana | findstr -i smtp`).

---

## Lab 3.3 - Configure Slack alerts (10 min)

### Option A - Real Slack Incoming Webhook

1. Slack → Create app → Incoming Webhooks → On
2. Add webhook to channel `#grafana-alerts` (or any channel you control)
3. Copy the webhook URL

### Option B - No Slack available

Use https://webhook.site - copy your unique URL and choose integration **Webhook** instead of Slack (payload still proves routing).

### Grafana contact point

1. **Contact points → Add contact point**
2. Name: `slack-oncall`
3. Integration: **Slack** (or Webhook for Option B)
4. Paste webhook URL; recipient `#grafana-alerts`
5. Title template:

```
[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}
```

6. Text template:

```
{{ len .Alerts.Firing }} firing
{{ .CommonAnnotations.summary }}
```

7. **Send test notification** - confirm channel / webhook.site
8. **Notification policies → New nested / child policy**
9. Matcher: `severity` `=` `critical`
10. Contact point: `slack-oncall`
11. Save

**Checkpoint:** Test message appears; routing tree shows child under default.

**404 from Slack?** Webhook URL truncated on paste.

---

## Lab 3.4 - Test notifications end to end (15 min)

### 1) Force CPU load (pick one)

**Windows (PowerShell) - burn some CPU briefly:**

```powershell
1..4 | ForEach-Object {
  Start-Job { while ($true) { $null = 1*1 } }
}
# Later stop:
Get-Job | Stop-Job; Get-Job | Remove-Job
```

**Linux / WSL / macOS:**

```bash
stress-ng --cpu 4 --timeout 300s
# or
for i in 1 2 3 4; do yes > /dev/null & done
# stop later
kill %1 %2 %3 %4
```

If you lowered the threshold to 5, even mild load (or idle noise) may be enough.

### 2) Watch rule states

**Alerting → Alert rules → HighCpuUsage**

```
Normal → Pending (~2m) → Alerting
```

### 3) Check channels

- MailHog: http://localhost:8025
- Slack / webhook.site
- **Alerting → Alert groups** - one bundled group

### 4) Silence

1. **Alerting → Silences → Add silence**
2. Matcher: `alertname` `=` `HighCpuUsage`
3. Duration: 15m
4. Confirm further notifications stop while rule may still evaluate

### 5) Resolve

1. Stop the CPU stress jobs
2. Wait for state → Normal
3. Confirm resolved notification (if enabled on contact point)

---

## Verification checklist

- [ ] Rule moved to Pending within one evaluation interval
- [ ] Rule moved to Alerting after pending period
- [ ] Email arrived in MailHog
- [ ] Slack/webhook received critical-route notification
- [ ] Alert groups shows a bundled group
- [ ] Silence stopped further notifications
- [ ] Resolved after load dropped

---

## Alerting hygiene (from wrap-up)

| Problem | Fix |
|---|---|
| Nothing arrives | Test contact point; check matcher typos |
| Too many messages | Longer pending, fewer group-by labels, longer repeat interval |
| Flapping | `avg_over_time`, longer pending |
| No Data storms | Choose No Data → Normal vs Alerting deliberately |
| Unowned alerts | Add `runbook_url` or delete the rule |

---

## Files in this lab

| File | Purpose |
|---|---|
| `docker-compose.yml` | Grafana + Prometheus + node-exporter + MailHog |
| `grafana/grafana.ini` | SMTP → MailHog |
| `prometheus/prometheus.yml` | Scrape node exporter |
| `provisioning/datasources/datasources.yml` | Prometheus DS |

---

## Cleanup

```bash
docker compose down
# wipe alert history / DB:
docker compose down -v
```

---

## Homework before Day 4

Add one alert for a service you own - with `severity`, `runbook_url`, and a contact point that reaches you.
