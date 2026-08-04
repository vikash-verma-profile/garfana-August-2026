# Lab 3 — ready-to-paste queries

## Prometheus

### CPU busy %
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])) * 100)
```

### Memory available (bytes)
```promql
node_memory_MemAvailable_bytes
```

### Disk used % (adjust mountpoint if needed)
```promql
100 - ((node_filesystem_avail_bytes{fstype!="tmpfs",mountpoint="/"} * 100) / node_filesystem_size_bytes{fstype!="tmpfs",mountpoint="/"})
```

### Request rate by instance
```promql
sum by (instance) (rate(http_requests_total[5m]))
```

### Latency histogram buckets (Heatmap)
```promql
sum by (le) (rate(http_request_duration_seconds_bucket[5m]))
```

### Target up
```promql
up{job="node"}
```

---

## PostgreSQL

### Top orders
```sql
SELECT
  id,
  status,
  region,
  amount,
  created_at
FROM orders
WHERE $__timeFilter(created_at)
ORDER BY amount DESC
LIMIT 10;
```

### Geomap — orders by region
```sql
SELECT
  r.latitude,
  r.longitude,
  o.region,
  COUNT(*) AS orders,
  ROUND(SUM(o.amount)::numeric, 2) AS revenue
FROM orders o
JOIN regions r ON r.region = o.region
WHERE $__timeFilter(o.created_at)
GROUP BY r.latitude, r.longitude, o.region
ORDER BY orders DESC;
```

### Duration buckets (alternate Heatmap / Time series)
```sql
SELECT
  $__timeGroup(created_at, '5m') AS time,
  CASE
    WHEN duration_ms < 50 THEN '0-50ms'
    WHEN duration_ms < 100 THEN '50-100ms'
    WHEN duration_ms < 250 THEN '100-250ms'
    WHEN duration_ms < 500 THEN '250-500ms'
    ELSE '500ms+'
  END AS metric,
  COUNT(*) AS value
FROM api_requests
WHERE $__timeFilter(created_at)
GROUP BY 1, 2
ORDER BY 1;
```

### Orders over time by status
```sql
SELECT
  $__timeGroup(created_at, '5m') AS time,
  status AS metric,
  COUNT(*) AS value
FROM orders
WHERE $__timeFilter(created_at)
GROUP BY 1, 2
ORDER BY 1;
```
