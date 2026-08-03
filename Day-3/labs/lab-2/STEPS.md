# Lab 2 - Panel Transformations

**Course:** Grafana Monitoring & Observability - Day 3  
**Module:** Transformations (Guided Practice 10)  
**Duration:** ~25–35 minutes  
**Depends on:** Day-2 stack + [Lab 1](../lab-1/STEPS.md)

---

## Objectives

1. Build a Table panel with two Prometheus queries (CPU + memory)
2. **Join by field** on `time`
3. **Organize fields** (hide/rename)
4. **Filter data by values**
5. Prove that transformation **order** matters
6. Compare before/after with Inspector → Data → Apply transformations toggle

---

## Theory reminder

Transformations run **in the browser**, top to bottom. Prefer aggregating in PromQL/SQL when possible - heavy transforms on wall boards hurt performance.

| Goal | Transformation |
|---|---|
| Two metrics side by side | Join by field (time) |
| One list from many same-shaped queries | Merge |
| Totals per region/service | Group by |
| Single number per series | Reduce |
| Readable names | Rename / Rename by regex |
| Tidy columns | Organize fields |
| Keep rows above a threshold | Filter data by values |

---

## Step 1 - New Table panel

1. New dashboard (or edit `Day3 Query Practice`)
2. Add visualization → **Table**
3. Data source: **Prometheus**
4. Time range: Last 15 minutes

---

## Step 2 - Query A: CPU per instance

**Query A:**

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])) * 100)
```

Legend: `{{instance}}`  
Min step / interval: leave default or 15s

---

## Step 3 - Query B: Memory per instance

**Add query B:**

```promql
100 * (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

Legend: `{{instance}}`

---

## Step 4 - Join by field

1. Open **Transform** tab
2. Add **Join by field**
3. Mode: outer / join on `Time` (or `time` - match your field name)
4. Observe columns combining CPU and Memory on the same timestamps

---

## Step 5 - Organize fields

1. Add **Organize fields**
2. Hide noisy label columns (if any)
3. Rename value fields to `CPU` and `Memory`
4. Reorder so: time → instance/host → CPU → Memory

---

## Step 6 - Filter by values

1. Add **Filter data by values**
2. Condition: `CPU` **greater than** `50` (or `0.5` if your field is a ratio 0–1 - match your unit)
3. Confirm only busy hosts remain

> If nothing remains, lower the threshold (lab hosts are often idle). Try `> 1` for percent CPU.

---

## Step 7 - Break it on purpose (order matters)

1. Drag **Filter** **above** **Join**
2. Observe broken/empty results
3. Undo / drag Filter back **below** Join
4. Open **Inspect → Data** and toggle **Apply panel transformations** to see before vs after

---

## Step 8 - Discussion prompt

Which of these steps would be better done in the query itself?  
Example: filter hosts in PromQL with `> boolean` or recording rules vs client-side Filter on a 10s refresh wall board.

---

## Success criteria

- [ ] Table shows time + host + CPU + Memory as clean columns
- [ ] Filter keeps only hosts above your CPU threshold (or you documented why none qualify)
- [ ] You demonstrated that Filter-before-Join breaks the result
- [ ] Inspector before/after toggle used

---

## Optional Reduce drill

New Stat panel:

1. Query CPU busy %
2. Transform → **Reduce** → Series to rows → Last / Mean
3. Note how Reduce feeds Stat/Gauge/Bar gauge

---

## Next lab

**[Lab 3 - Alerting End to End](../lab-3/STEPS.md)** - stop Day-2 stack if needed, then start Lab 3 Compose (includes MailHog).
