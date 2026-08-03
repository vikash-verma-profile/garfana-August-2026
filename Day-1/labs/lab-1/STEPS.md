# Lab 1Stand Up Grafana with Docker

**Course:** Grafana Monitoring & ObservabilityDay 1  
**Module:** Installation & Initial Configuration (Hands-on Lab)  
**Duration:** ~45 minutes  
**Format:** Work individually or in pairs

---

## Objectives

By the end of this lab you will be able to:

1. Install Docker and verify the engine runs
2. Deploy Grafana OSS using Docker Compose
3. Log in at `http://localhost:3000` and complete first-time setup
4. Confirm the Clock panel plugin was installed automatically
5. Start, stop, and inspect the stack with Compose commands

---

## Prerequisites

| Requirement | Notes |
|---|---|
| RAM | At least 8 GB recommended |
| Disk | ~2 GB free for images and volumes |
| Ports | **3000** must be free on the host |
| Rights | Admin rights to install Docker Desktop (Windows/macOS) |
| Network | Internet access to pull `grafana/grafana-oss` |
| Files | This folder: `labs/lab-1/docker-compose.yml` |

---

## Architecture reminder (from Day 1 theory)

```
Browser  →  Grafana UI (port 3000)  →  Grafana backend (Go)
                                      →  SQLite DB in /var/lib/grafana
                                      →  Plugins under /var/lib/grafana/plugins
```

Grafana stores **dashboards, users, and settings** in its own database.  
It does **not** store metricsthose come later from data sources (Day 2: Prometheus).

---

## Step 1Install Docker

### Windows / macOS

1. Download **Docker Desktop** from [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
2. Run the installer and complete setup
3. Start Docker Desktop and wait until the status shows **Running**
4. On Windows, ensure the WSL 2 backend is enabled if prompted

### Linux (Ubuntu / Debian example)

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
# Follow official Docker CE install docs for your distro, then:
sudo usermod -aG docker $USER
# Log out and back in so the docker group applies
```

---

## Step 2Verify the Docker engine

Open a terminal (PowerShell, CMD, or bash) and run:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

**Expected results:**

- `docker --version` prints a version string (e.g. Docker version 27.x)
- `docker compose version` prints Compose v2.x
- `hello-world` downloads a small image and prints a success message

**If it fails:**

| Symptom | Fix |
|---|---|
| `docker` not found | Restart terminal after install; confirm Docker Desktop is running |
| Permission denied (Linux) | Add user to `docker` group and re-login |
| Engine not running | Start Docker Desktop / `sudo systemctl start docker` |

---

## Step 3Review the Compose file

Open `labs/lab-1/docker-compose.yml`. Key parts:

| Setting | Purpose |
|---|---|
| `image: grafana/grafana-oss:latest` | Official open-source Grafana image |
| `ports: "3000:3000"` | Host port 3000 → container port 3000 |
| `volumes: grafana-data:/var/lib/grafana` | Persist DB, plugins, and dashboards |
| `GF_SECURITY_ADMIN_USER` / `PASSWORD` | Initial admin credentials |
| `GF_INSTALL_PLUGINS=grafana-clock-panel` | Auto-install Clock panel on first start |
| `restart: unless-stopped` | Restart container after host reboot (unless you stopped it) |
| `healthcheck` | Compose can report when Grafana is ready |

> **Precedence reminder (Module 3):** defaults.ini → grafana.ini → **environment variables**.  
> `GF_SECURITY_ADMIN_PASSWORD` wins over the default `admin` prompt behavior for first boot.

---

## Step 4Bring the stack up

In a terminal, change to this lab folder:

```bash
cd labs/lab-1
```

Windows (PowerShell):

```powershell
cd c:\Users\admin\Desktop\grafana\Day-1\labs\lab-1
```

Start Grafana in the background:

```bash
docker compose up -d
```

Check status:

```bash
docker compose ps
docker compose logs -f grafana
```

Press `Ctrl+C` to stop following logs (the container keeps running).

**Expected `ps` output:** container `grafana` with status `Up` (and ideally healthy).

**Pull / start troubleshooting:**

| Symptom | Fix |
|---|---|
| Port already allocated | Stop whatever uses 3000, or change host port to `"3001:3000"` |
| Image pull timeout | Check internet / proxy; retry `docker compose pull` |
| Container exits immediately | Run `docker compose logs grafana` and read the last error |

---

## Step 5First login

1. Open a browser to [http://localhost:3000](http://localhost:3000)
2. Sign in with:
   - **User:** `admin`
   - **Password:** `admin`
3. When prompted, set a **new strong password** and save it
   - For training only you may keep a simple password; never do this in production
4. You should land on the Grafana **Home** page

**Verify health API (optional):**

```bash
curl http://localhost:3000/api/health
```

Or in PowerShell:

```powershell
Invoke-RestMethod http://localhost:3000/api/health
```

Expected JSON includes `"database": "ok"`.

---

## Step 6Confirm the Clock plugin

The Compose file sets `GF_INSTALL_PLUGINS=grafana-clock-panel`, so the plugin installs on first start.

1. In Grafana, open the left navigation
2. Go to **Administration** → **Plugins and data** → **Plugins**  
   (wording may vary slightly by Grafana version: **Administration → Plugins**)
3. Search for **Clock**
4. Confirm **Clock** is listed and enabled

You will use this panel visually in Lab 2 when building a tiny test dashboard.

---

## Step 7Essential Compose lifecycle commands

Practice these until they feel natural:

```bash
# Status
docker compose ps

# Follow logs
docker compose logs -f grafana

# Stop containers (keeps the named volume = dashboards survive)
docker compose stop

# Start again
docker compose start

# Stop and remove containers (volume still kept)
docker compose down

# Full wipe including dashboards/plugins DB (destructive)
docker compose down -v
```

**Lab checkpointpersistence:**

1. While Grafana is up, note that you changed the admin password
2. Run `docker compose down` then `docker compose up -d`
3. Log in again with your **new** password (not `admin`/`admin` if you changed it)

If the old password still works after `down` + `up`, the `grafana-data` volume is working.

---

## Step 8Inspect where data lives (optional but recommended)

List the volume:

```bash
docker volume ls | findstr grafana
```

On Linux/macOS:

```bash
docker volume ls | grep grafana
```

Exec into the container and list Grafana paths:

```bash
docker exec -it grafana sh -c "ls -la /var/lib/grafana && ls -la /etc/grafana"
```

| Path inside container | Role |
|---|---|
| `/var/lib/grafana` | SQLite DB, plugins, session data**needs a volume** |
| `/etc/grafana` | Configuration (`grafana.ini`) |
| `/var/log/grafana` | Logs (often to stdout in Docker) |
| `/usr/share/grafana` | Binaries and web assets |

---

## Success criteria checklist

Mark each item when done:

- [ ] `docker --version` and `docker compose version` work
- [ ] `docker compose up -d` starts container `grafana`
- [ ] [http://localhost:3000](http://localhost:3000) shows the login page
- [ ] You logged in and set/confirmed an admin password
- [ ] Clock panel plugin appears under Administration → Plugins
- [ ] After `docker compose down` and `up -d`, Grafana still has your password / data
- [ ] You can start and stop the container on demand

---

## Cleanup (end of day / before reset)

Keep the volume if you will continue with Lab 2:

```bash
docker compose stop
```

Reset everything for a clean retry:

```bash
docker compose down -v
```

---

## Common ports reference (Day 1)

| Port | Service |
|---|---|
| 3000 | Grafana web UI |
| 9090 | Prometheus (Day 2+) |
| 3100 | Loki |
| 9100 | node_exporter |

---

## What you practiced vs Day 1 theory

| Theory topic | What you just did |
|---|---|
| Why monitoring matters | Prepared the visualization layer of the stack |
| Grafana architecture | Ran the Go backend + React UI in Docker |
| Installation options | Used the **recommended Docker** path for labs |
| Config precedence | Set admin user/password via `GF_*` env vars |
| Plugins | Installed `grafana-clock-panel` via `GF_INSTALL_PLUGINS` |

---

## Next lab

Continue with **[Lab 2Grafana UI Walkthrough & Administration](../lab-2/STEPS.md)** using this same running instance.
