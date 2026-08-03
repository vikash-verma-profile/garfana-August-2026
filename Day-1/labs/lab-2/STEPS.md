# Lab 2Grafana UI Walkthrough & Administration

**Course:** Grafana Monitoring & ObservabilityDay 1  
**Modules:** Grafana UI Walkthrough + Lab completion criteria  
**Duration:** ~45–60 minutes  
**Depends on:** [Lab 1](../lab-1/STEPS.md) completed (Grafana reachable on port 3000)

---

## Objectives

By the end of this lab you will be able to:

1. Navigate Home, Dashboards, Explore, Alerting, Connections, and Administration
2. Use Search to find dashboards and panels
3. Run an ad-hoc query in **Explore** using the built-in Grafana data source
4. Create a simple dashboard with Time series, Stat, and Clock panels
5. Review users, roles, organizations, and installed plugins
6. (Optional) Restart with file provisioning and open the Day-1 sample dashboard

---

## Prerequisites

- Lab 1 stack is running **or** you can start the Lab 2 Compose file in this folder
- Browser access to [http://localhost:3000](http://localhost:3000)
- Admin credentials from Lab 1

### Option AContinue Lab 1 container (recommended)

```bash
cd labs/lab-1
docker compose ps
# If stopped:
docker compose up -d
```

### Option BStart Lab 2 stack (adds dashboard provisioning)

If the Lab 1 container is still running, stop it first to free the name/port:

```bash
cd labs/lab-1
docker compose down
```

Then:

```bash
cd labs/lab-2
docker compose up -d
docker compose logs -f grafana
```

Provisioning mounts:

| Host path | Container path | Purpose |
|---|---|---|
| `./provisioning` | `/etc/grafana/provisioning` | Auto-load dashboard provider |
| `./dashboards` | `/etc/grafana/dashboards` | JSON dashboard files |

After startup, look under **Dashboards → Day-1 Labs → Day-1 Lab Home**.

---

## Concept map (from Day 1 Module 2)

Remember the nesting:

```
Organization
  └── Folder
        └── Dashboard
              └── Panel
                    └── Query  →  Data source
```

Today you mostly use the built-in **`-- Grafana --`** data source (random walk / test data).  
Real metrics arrive when you connect **Prometheus** on Day 2.

---

## Step 1Home dashboard & navigation rail

1. Log in at [http://localhost:3000](http://localhost:3000)
2. Identify these areas:
   - **Left navigation rail**Home, Dashboards, Explore, Alerting, Connections, Administration
   - **Top bar**breadcrumbs, time picker, refresh, search
   - **Center canvas**dashboard or landing content
3. Click **Home**
4. Note what appears as the landing page (default Grafana welcome vs a custom home)

**Checkpoint:** You can open and close the nav rail and return to Home without getting lost.

---

## Step 2Search

1. Open **Search** (magnifying glass) or press the search shortcut shown in the UI
2. Type `grafana` or `home`
3. Observe results for dashboards / folders / panels (depending on version)
4. Clear search and return to Home

**Why it matters:** In large orgs, search is faster than clicking through folders.

---

## Step 3Connections (data sources)

1. Go to **Connections** → **Data sources**  
   (older UIs: **Configuration → Data sources**)
2. List what is already present
3. Open the built-in **Grafana** data source if shown
4. Do **not** add Prometheus yetthat is Day 2

**Theory link:** Grafana queries data sources **live at render time**. It does not store metric samples in its SQLite DB.

---

## Step 4Explore (ad-hoc queries)

Explore lets you query without creating a dashboard.

1. Open **Explore** from the nav rail
2. Select data source **Grafana** (built-in)
3. Choose a test query such as **Random Walk** / **Scenario** (labels vary by version)
4. Set time range to **Last 15 minutes**
5. Click **Run query** (or wait for auto-refresh)
6. Switch visualization between graph and table if available
7. Optional: click **Add to dashboard** and save to a new dashboard named `Explore Scratch`

**Checkpoint:** You can explain the difference between **Explore** (investigation) and a **Dashboard** (saved operational view).

---

## Step 5Build your first dashboard by hand

1. Go to **Dashboards** → **New** → **New dashboard**
2. Click **Add visualization**
3. Data source: **Grafana** → Random Walk (or equivalent test data)
4. Visualization type: **Time series**
5. Panel title: `Demo Traffic`
6. Apply / Save panel
7. Click **Add** → **Visualization** again
8. Same data source; visualization: **Stat**
9. Title: `Latest Value`
10. Add a third panel: visualization type **Clock** (plugin from Lab 1)
11. Title: `Local Time`
12. Click **Save dashboard**
    - Name: `Day1 My First Dashboard`
    - Folder: General (or create folder `Day-1 Labs`)

### Panel types you just used

| Panel | Typical use |
|---|---|
| Time series | Trends over time (latency, RPS, CPU) |
| Stat | Single important number (error rate, up status) |
| Clock | Wall clock / timezone awareness in NOC walls |

### Optional polish

- Set dashboard **refresh** to `10s`
- Open panel **edit** → **Thresholds** on the Stat panel (green below 80, red abovedemo only)
- Drag panels to rearrange the grid

---

## Step 6Folders, export, and JSON model

1. From your dashboard, open the share/export menu (or **Dashboard settings**)
2. Open **JSON Model** (or **Export → Save as JSON**)
3. Skim the structure: `panels`, `time`, `templating`, `uid`
4. Optional: export JSON to `Day1-My-First-Dashboard.json` on your desktop

**Theory link:** Dashboards are versioned JSONthey can be exported, stored in Git, and **provisioned as code** (you already have an example under `labs/lab-2/dashboards/`).

---

## Step 7Administration: users, orgs, plugins

### Users & roles

1. Open **Administration** → **Users and access** → **Users**  
   (wording may be **Server Admin → Users** if you use the shield icon)
2. Confirm your `admin` user exists
3. Review role meanings from Day 1 theory:

| Role | Capabilities |
|---|---|
| Grafana Admin | Server-wide: orgs, users, global settings |
| Org Admin | Full control inside one organization |
| Editor | Create/edit dashboards; cannot manage users |
| Viewer | Read-only dashboards |

Optional stretch:

1. Create a user `viewer1` with role **Viewer**
2. Log out, log in as `viewer1`
3. Confirm you can open dashboards but cannot save edits
4. Log back in as admin

### Organizations

1. Find **Organizations** under Administration
2. Note the default org (usually **Main Org.**)
3. Read-only for this labcreating extra orgs is optional

### Plugins

1. **Administration → Plugins**
2. Confirm **Clock** is installed
3. Browse the catalogue (do not install large app plugins on shared lab machines unless asked)
4. Optional CLI install pattern (inside container):

```bash
docker exec -it grafana grafana cli plugins install grafana-piechart-panel
docker restart grafana
```

> Prefer catalogue / `GF_INSTALL_PLUGINS` in Compose for repeatable labs.

---

## Step 8Alerting & Administration glance (read-only)

1. Open **Alerting**
2. Note sections: Alert rules, Contact points, Notification policies
3. Do **not** configure production contact points yet
4. Open **Administration → General / Settings** (if available) and note server stats

**Day 1 takeaway:** Alerting UI exists here; wiring Prometheus-backed alert rules comes later in the course.

---

## Step 9Persistence & rebuild drill

Prove you can recover your work:

```bash
# From the folder whose compose you used (lab-1 or lab-2)
docker compose down
docker compose up -d
```

Then verify:

- [ ] Login still works with your password
- [ ] `Day1 My First Dashboard` (or provisioned `Day-1 Lab Home`) is still present
- [ ] Clock plugin is still listed

Destructive reset (only if instructor asks):

```bash
docker compose down -v
```

---

## Step 10Recap questions (before Day 2)

Answer these without looking at notes if possible:

1. Name the **three pillars** of observability and one question each answers.
2. Does Grafana store Prometheus metrics in its SQLite database? Why/why not?
3. Which port is the Grafana UI on by default?
4. Where does Grafana persist plugins and the DB **inside** the container?
5. What is the difference between **Explore** and a **Dashboard**?
6. Which Compose environment variable installs plugins at startup?

---

## Success criteria checklist

- [ ] Can navigate Home, Dashboards, Explore, Connections, Administration
- [ ] Ran a query successfully in Explore
- [ ] Created and saved a dashboard with at least two panel types
- [ ] Located Clock under Plugins
- [ ] Explained Viewer vs Editor vs Admin at a high level
- [ ] Restarted the stack and confirmed dashboards survived
- [ ] (Optional) Opened provisioned **Day-1 Lab Home** from Lab 2 Compose

---

## Files in this lab

| File | Purpose |
|---|---|
| `STEPS.md` | This document |
| `docker-compose.yml` | Grafana + provisioning mounts |
| `provisioning/dashboards/dashboards.yml` | File provider for lab dashboards |
| `provisioning/datasources/datasources.yml` | Empty placeholder (Prometheus on Day 2) |
| `dashboards/day1-home.json` | Sample dashboard (Clock + Stat + Time series) |

---

## Coming in Day 2

- Connect **Prometheus** as a data source
- Build dashboards from real metrics with PromQL
- Panel transformations, thresholds, and template variables
