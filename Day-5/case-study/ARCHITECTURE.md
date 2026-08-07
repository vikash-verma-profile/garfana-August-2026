# ShopFront - Architecture Diagrams

Open this file in any Markdown preview that supports **Mermaid** (VS Code / Cursor preview, GitHub, etc.).

Companion `.mmd` sources live in [`diagrams/`](diagrams/) for export to PNG/SVG via [mermaid.live](https://mermaid.live).

---

## 1. Context - who talks to what

```mermaid
C4Context
title ShopFront Observability Context

Person(customer, "Shopper", "Browses catalog, checks out")
Person(oncall, "On-call engineer", "Responds to alerts")
Person(biz, "Ops / Merchandising", "Watches order KPIs")

System_Boundary(sf, "ShopFront Platform") {
  System(api, "ShopFront API", "Catalog, cart, checkout simulation")
  SystemDb(db, "PostgreSQL", "Orders & amounts")
  System(prom, "Prometheus", "Metrics TSDB")
  System(gf, "Grafana", "Dashboards & Unified Alerting")
  System(mail, "MailHog", "Lab email sink")
}

Rel(customer, api, "HTTPS /checkout")
Rel(api, db, "SQL writes")
Rel(prom, api, "Scrape /metrics")
Rel(gf, prom, "PromQL")
Rel(gf, db, "SQL panels")
Rel(gf, mail, "Alert emails")
Rel(oncall, gf, "Investigate")
Rel(biz, gf, "KPI dashboards")
```

> If C4 Mermaid is unsupported in your preview, use the flowchart below.

```mermaid
flowchart LR
  subgraph Users
    C[Shoppers]
    O[On-call]
    B[Business]
  end

  subgraph ShopFront
    API[ShopFront API :8080]
    PG[(PostgreSQL :5432)]
  end

  subgraph Observability
    P[Prometheus :9090]
    G[Grafana :3000]
    M[MailHog :8025]
    N[node_exporter]
    X[postgres_exporter]
  end

  C -->|HTTP| API
  API --> PG
  P -->|scrape /metrics| API
  P -->|scrape| N
  P -->|scrape| X
  G -->|PromQL| P
  G -->|SQL| PG
  G -->|SMTP alerts| M
  O --> G
  B --> G
```

---

## 2. Container / lab deployment view

```mermaid
flowchart TB
  subgraph Docker Compose network: shopfront-net
    GF[grafana]
    PR[prometheus]
    API[shopfront-api]
    PG[postgres]
    PE[postgres-exporter]
    NE[node-exporter]
    MH[mailhog]
  end

  Browser((Browser)) -->|:3000| GF
  Browser -->|:8080| API
  Browser -->|:9090| PR
  Browser -->|:8025| MH

  PR -->|shopfront:8080/metrics| API
  PR -->|node-exporter:9100| NE
  PR -->|postgres-exporter:9187| PE
  PE --> PG
  API --> PG
  GF --> PR
  GF --> PG
  GF -->|smtp mailhog:1025| MH
```

---

## 3. Metrics pipeline (how a panel gets data)

```mermaid
sequenceDiagram
  autonumber
  participant App as ShopFront API
  participant Prom as Prometheus
  participant GF as Grafana Panel
  participant User as Browser

  loop every 15s
    Prom->>App: GET /metrics
    App-->>Prom: http_requests_total{route,status} …
    Prom->>Prom: Append samples to TSDB
  end

  User->>GF: Open dashboard (Last 6h, refresh 30s)
  GF->>Prom: POST /api/v1/query_range (PromQL)
  Prom-->>GF: Instant/range vectors
  GF->>GF: Data frames → transform → visualize
  GF-->>User: RED panels + thresholds
```

---

## 4. Checkout request path (business + metrics)

```mermaid
flowchart LR
  A[POST /checkout] --> B{Validate cart}
  B -->|ok| C[Charge payment simulator]
  B -->|bad request| E4[4xx + counter]
  C -->|success| D[Insert order row]
  C -->|decline / timeout| E5[5xx or 402 + counter]
  D --> OK[200 + latency histogram]
  E4 --> H[Observe histogram + labels]
  E5 --> H
  OK --> H
```

---

## 5. Alerting path (Unified Alerting)

```mermaid
flowchart TB
  Q[Alert query: checkout p95] --> R[Reduce Last]
  R --> T{Threshold > 0.5s}
  T -->|false| N[Normal]
  T -->|true| P[Pending  for 2–5m]
  P --> F[Alerting]
  F --> Pol[Notification policy]
  Pol --> CP[Contact point: ops-email]
  CP --> MH[MailHog UI]
```

---

## 6. Dashboards as code (Day 5 discipline)

```mermaid
flowchart LR
  Git[Git repo] --> Files[JSON + YAML on disk]
  Files --> Prov[Grafana provisioning]
  Prov --> UI[Read-only dashboards]
  UI -.->|no Save in prod| Git
```

---

## 7. Folder & permission sketch (production mindset)

```mermaid
flowchart TB
  Org[Main Org]
  Org --> F1[10 · ShopFront-Prod]
  Org --> F2[90 · Sandbox]
  F1 --> T1[Team Checkout = Edit]
  F1 --> T2[Team Biz = View]
  F2 --> T3[Everyone = Edit]
```

---

## Ports quick reference

| Port | Service |
|---|---|
| 3000 | Grafana |
| 8080 | ShopFront API |
| 9090 | Prometheus |
| 9100 | node_exporter |
| 9187 | postgres_exporter |
| 5432 | PostgreSQL |
| 1025 / 8025 | MailHog SMTP / UI |
