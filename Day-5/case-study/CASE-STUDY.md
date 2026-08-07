# ShopFront Case Study - Brief

## Company

**ShopFront** is a regional e-commerce brand (fashion + home). Peak traffic is evenings and weekend flash sales. Leadership cares about **conversion** and **checkout reliability**; engineering cares about **latency, errors, and capacity**.

You are the observability engineer joining for a 1-day engagement: stand up metrics visibility for the checkout path and prove an actionable alert before Black Friday prep.

---

## Current state (pain)

- Ops only has host CPU graphs - no view of *orders failing*
- When checkout slows, support hears it from customers first
- Staging and production dashboards were clicked together and have drifted
- No alert owns the checkout SLO; nighttime pages go to a shared inbox nobody reads

---

## Architecture (logical)

ShopFront’s online store is a small set of services behind an API gateway pattern (simplified for the lab into **one instrumented ShopFront API** that simulates catalog, cart, and checkout):

```
Customers → ShopFront API → PostgreSQL (orders)
                 ↓
            /metrics (Prometheus)
                 ↓
         Grafana (dashboards + alerts)
```

Full diagrams: [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Service map (lab model)

| Component | Role | Port |
|---|---|---|
| `shopfront-api` | Simulated storefront API + Prometheus metrics | 8080 |
| `postgres` | Orders / business data for SQL panels | 5432 |
| `postgres-exporter` | DB health metrics | 9187 |
| `node-exporter` | Host / container resource metrics | 9100 |
| `prometheus` | Scrape + TSDB | 9090 |
| `loki` *(optional path)* | Log labels for drill-down story | 3100 |
| `grafana` | Visualize + alert | 3000 |
| `mailhog` | Catch alert emails in class | 8025 |

---

## Golden signals for ShopFront

### RED (API / checkout)

| Signal | Question | Example metric |
|---|---|---|
| **Rate** | How busy is checkout? | `rate(http_requests_total{route="/checkout"}[5m])` |
| **Errors** | Are payments failing? | `rate(http_requests_total{route="/checkout",status=~"5.."}[5m])` |
| **Duration** | Is checkout slow? | `histogram_quantile(0.95, … http_request_duration_seconds_bucket{route="/checkout"})` |

### USE (infrastructure)

| Signal | Question |
|---|---|
| Utilization | Is CPU / memory saturated? |
| Saturation | Are we queuing / thrashing? |
| Errors | Are exporters / scrapes down? (`up == 0`) |

### Business

| KPI | Source in lab |
|---|---|
| Orders per minute | Prometheus counter **or** SQL on `orders` |
| Revenue proxy | SQL `SUM(amount)` over dashboard range |
| Payment success ratio | Labels `status="200"` vs `status="402|500"` on checkout |

---

## SLO (agreed with product)

| SLO | Target | Burn alert idea |
|---|---|---|
| Checkout availability | 99.5% successful (non-5xx) over 30d | Error budget / burn (simplified in lab) |
| Checkout latency | p95 &lt; **500 ms** | Alert if p95 &gt; 500ms for 5 minutes |
| Order pipeline | ≥ 1 successful order / min in business hours (lab: any traffic) | Low order rate warning |

For class we implement the **latency SLO alert** end-to-end.

---

## Personas & dashboards

| Persona | Needs | Dashboard |
|---|---|---|
| On-call engineer | RED + host health, drill to instance | E-Commerce Overview |
| Checkout squad lead | Latency by route, error breakdown | (same board, Checkout row) |
| Business stakeholder | Orders & revenue trend | Business KPI row / SQL panels |
| Platform SRE | Target up, scrape health, DB | Infrastructure row |

---

## Incident scenarios (work these in STEPS)

### Scenario A - Silent checkout failures

Flash sale starts. Error rate on `/checkout` climbs to 8%. CPU looks fine.  
**Prove:** metrics catch it before Twitter does. Alert should fire on error ratio or latency.

### Scenario B - Slow payments

p95 checkout latency rises from 180ms → 900ms. Order rate drops.  
**Prove:** latency panel + alert; correlate with DB time or synthetic delay flag.

### Scenario C - Exporter / scrape death

`shopfront` target goes DOWN. Dashboards show “No data”.  
**Prove:** `up{job="shopfront"}` alert / row turns red; you don’t blame the app code first.

---

## Acceptance criteria (definition of done)

- [ ] Stack starts with one `docker compose up -d --build`
- [ ] Prometheus targets: `shopfront`, `node`, `postgres`, `prometheus` are **UP**
- [ ] Grafana has Prometheus + PostgreSQL data sources (provisioned)
- [ ] **E-Commerce Overview** dashboard shows Rate / Errors / Duration + business SQL
- [ ] Template variable `instance` (or `job`) filters panels
- [ ] Alert **ShopFrontCheckoutP95High** exists; test notification lands in MailHog
- [ ] You can explain the architecture diagram to a non-Grafana audience in 3 minutes

---

## Stretch (if time)

- Add Loki + ship API logs; link from a metric panel (derived fields story)
- Export dashboard JSON and commit as the “source of truth”
- Terraform folder + team permission for `ShopFront` (reuse Day-5 Lab 3 pattern)
- Put Nginx TLS in front (reuse Day-5 Lab 4)

---

## Discussion questions (wrap-up)

1. Which panels are **engineering** vs **business** - should they share one board?
2. Where do you put high-cardinality labels (user_id, cart_id) - and why never?
3. If staging and prod must stay identical, what belongs in Git vs the UI?
4. Who owns the checkout latency alert at 2am - and where is the runbook URL?
