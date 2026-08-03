# Capstone - Observability Stack as Code

**Course:** Grafana Monitoring & Observability - Day 5  
**Brief:** Acme Payments - empty VM, new service, everything in Git  
**Format:** 30 minutes to plan/start in class · finish as homework · 5-minute demo

---

## The brief (from the deck)

1. Grafana behind Nginx with TLS and a correct `root_url`
2. Prometheus (and optionally Loki) data sources provisioned from YAML with fixed UIDs
3. Folders **Platform** and **Payments** created by Terraform, plus a team with Editor on Payments
4. Three dashboards as code:
   - Service overview (rate, errors, duration - RED)
   - Host health
   - Log errors (Loki optional; Prometheus error proxy acceptable for OSS labs)
5. One alert rule as code - p95 latency above 500ms for five minutes - with a contact point
6. A backup script + a restore you actually performed and timed
7. A README that shows a new engineer how to change a dashboard safely

---

## Suggested repository layout (already scaffolded here)

```text
capstone/
├── terraform/           # folders, teams, alerts (extend)
├── provisioning/        # datasources, dashboard providers
├── dashboards/
│   ├── platform/
│   └── payments/
├── scripts/backup.sh    # and/or backup.ps1
└── README.md            # engineer onboarding
```

Reuse patterns from Labs 2–4 rather than reinventing Compose.

---

## Step 1 - Plan (30 min in class)

Fill this checklist before coding:

- [ ] Which objects are **provisioning files** vs **Terraform** vs one-off API?
- [ ] Stable UIDs chosen for DS + dashboards + folders
- [ ] Where secrets live (env / secret manager - never Git)
- [ ] How CI would run `terraform plan` on a PR
- [ ] Backup ownership and restore RTO target

---

## Step 2 - Implement locally

1. Copy Lab 4 Nginx+TLS pattern or Lab 2 provisioning Compose as your base
2. Wire `provisioning/datasources` with fixed UIDs (`prom-main`, optional `loki-main`)
3. Place JSON under `dashboards/platform` and `dashboards/payments`
4. Terraform: folders + team + folder permission + optional alert rule group
5. Add `scripts/backup` + document restore timing from a real drill

Starter files in this folder are intentionally minimal - expand them to meet the rubric.

---

## Step 3 - Presentation (5 minutes)

Show:

1. The repo tree
2. `terraform plan` on a clean tree (No changes / expected adds)
3. One dashboard over HTTPS
4. The restore you ran and how many minutes it took

---

## Marking rubric (weights)

| Criterion | Weight | Full marks |
|---|---|---|
| Reproducibility | 25% | Clone + apply into empty Grafana, no manual clicks |
| Dashboard quality | 20% | Panels answer a stated question; units, thresholds, variables |
| Automation coverage | 20% | DS, folders, dashboards, alert rules from code |
| Security | 15% | TLS, no secrets in Git, least-privilege SA per pipeline |
| Recoverability | 10% | Backup script + performed restore with elapsed time |
| Documentation | 10% | README: clone → merged dashboard change |

---

## Self-check before you call it done

- [ ] Delete everything and apply again - does it come back?
- [ ] Is there a single secret anywhere in the repo?
- [ ] Does `terraform plan` report no changes on a clean apply?
- [ ] Can you restore without reading the internet?

---

## Where teams usually lose marks

- Dashboards built only in the UI and exported at the end
- Secrets committed “temporarily”
- A backup script nobody ever ran
- A README that only makes sense to the author

---

## Three habits worth keeping

1. Nothing gets clicked in production  
2. `uid` is the primary key  
3. A restore you have never run is not a backup  
