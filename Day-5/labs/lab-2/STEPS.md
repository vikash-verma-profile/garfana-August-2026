# Lab 2 - Provision Everything From Files

**Course:** Grafana Monitoring & Observability - Day 5  
**Module:** Dashboard Provisioning (Lab 2 · 20 min)  
**Duration:** ~20–30 minutes

---

## Objectives

1. Provision Prometheus (`uid: prom-lab2`) from YAML
2. Provision folders **platform** / **payments** via `foldersFromFilesStructure`
3. Load two dashboard JSON files with stable `uid` and `id: null`
4. Delete a dashboard in the UI and watch Grafana restore it

---

## Step 0 - Start with logs open

Stop Lab 1 if needed, then:

```bash
cd labs/lab-2
docker compose up -d
docker compose logs -f grafana
```

Login: http://localhost:3000 - `admin` / `admin`

---

## Tree you already have

```text
provisioning/
  datasources/prom.yaml      # uid prom-lab2
  dashboards/ops.yaml        # foldersFromFilesStructure: true
dashboards/
  platform/node-health.json
  payments/latency-slo.json
```

---

## Step 1 - Verify data source

**Connections → Data sources → Prometheus**  
UID should be `prom-lab2`, editable false, Save & test green.

---

## Step 2 - Verify folders & dashboards

Dashboards should show folders matching directory names:

- **platform** → Node Health (`uid: node-health`)
- **payments** → Payments · Latency SLO (`uid: payments-latency`)

Each tagged provisioned / day5. Open both - panels query Prometheus.

---

## Step 3 - Delete and wait for reconcile

1. In the UI, **delete** `Node Health`
2. Keep `docker compose logs -f grafana` visible
3. Wait ~30 seconds (`updateIntervalSeconds`)
4. Refresh Dashboards - **Node Health** returns

**Done when:** Both folders appeared without manual creation, and a deleted dashboard reappears on its own.

---

## Stretch

1. Set `allowUiUpdates: true` in `ops.yaml`, restart Grafana
2. Edit a panel in the UI and Save
3. Restart Grafana again - explain whether the file or the DB won
4. Set back to `false` for production-like behavior

---

## Behaviour cheatsheet

| Setting | Effect |
|---|---|
| `allowUiUpdates: false` | File always wins; UI Save disabled |
| `disableDeletion: false` | Removing file removes dashboard on next scan |
| `foldersFromFilesStructure` | Subdirs become Grafana folders |
| `updateIntervalSeconds: 30` | Disk rescan interval |

---

## Next lab

**[Lab 3 - Terraform](../lab-3/STEPS.md)** - reuse the service account token from Lab 1.
