# Lab 3 - Grafana as Terraform Code

**Course:** Grafana Monitoring & Observability - Day 5  
**Module:** Infrastructure as Code (Lab 3 · 25 min)  
**Duration:** ~25–35 minutes

---

## Objectives

1. Configure the Grafana Terraform provider with a service account token
2. Create folder `tf_lab` (`uid: tf-lab`) + Prometheus DS (`uid: prom-tf`)
3. Attach a dashboard from `dashboards/tf-lab.json`
4. Introduce UI drift, see it in `terraform plan`, then reconcile
5. Comment out the dashboard resource and observe a planned destroy

---

## Prerequisites

- Terraform **≥ 1.5** (`terraform version`)
- Grafana running (Lab 2 stack is fine) on http://localhost:3000
- Token from Lab 1 (`$env:TOKEN` / `GRAFANA_AUTH`)

```powershell
$env:GRAFANA_URL  = "http://localhost:3000"
$env:GRAFANA_AUTH = $env:TOKEN   # glsa_...
```

> Never commit tokens. Provider reads `GRAFANA_URL` and `GRAFANA_AUTH` from the environment.

---

## Step 1 - Init

```bash
cd labs/lab-3/terraform
terraform init
```

Review `provider.tf` and `main.tf`.

---

## Step 2 - Plan folder + data source

```bash
terraform plan -out tfplan
```

Read the plan. Then:

```bash
terraform apply tfplan
```

In the UI: folder **TF Lab** and data source **Prometheus TF** exist.

---

## Step 3 - Add the dashboard

`main.tf` already contains `grafana_dashboard.tf_lab` reading `dashboards/tf-lab.json`.

```bash
terraform plan -out tfplan
terraform apply tfplan
```

Open the dashboard under the TF Lab folder.

---

## Step 4 - Deliberate drift

1. In Grafana UI, rename the dashboard title
2. Run:

```bash
terraform plan
```

3. Find the drift (title change)
4. `terraform apply` to reconcile back to the file

**Done when:** A clean tree shows `No changes`, and your UI edit appeared as a plan diff before reconcile.

---

## Step 5 - See a destroy proposal

1. Comment out the `grafana_dashboard` resource in `main.tf`
2. `terraform plan` - confirm it wants to **destroy** the dashboard
3. Either apply (destroy) or uncomment to keep it

```bash
terraform state list
```

---

## Stretch

- Add `grafana_folder_permission` granting a team Editor
- Use `for_each` over a list of services to create one dashboard per service

---

## When to use what (deck rule)

| Approach | Best for |
|---|---|
| API scripts | One-offs, migrations, smoke tests |
| Provisioning files | Datasources + shared dashboards on every instance |
| Terraform | Folders, teams, permissions, alerting, multi-env |

Whichever owns an object, humans stop clicking it.

---

## Next lab

**[Lab 4 - Harden, Break & Restore](../lab-4/STEPS.md)**
