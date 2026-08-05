# Lab 4 - Custom Metrics in Grafana

Start here: **[STEPS.md](STEPS.md)**

```bash
# Stop other Day stacks first if ports 3000 / 9090 are taken
docker compose up -d --build
```

| Service | URL |
|---|---|
| Grafana | http://localhost:3000 (`admin` / `admin`) |
| Prometheus | http://localhost:9090 |
| Custom metrics API | http://localhost:8081 |
| Pushgateway | http://localhost:9091 |
| Provisioned dashboard | Dashboards → **Day 3 Lab 4 - Custom Metrics** |
