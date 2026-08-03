# Capstone - Acme Observability (starter README)

## Goal

Rebuild this Grafana estate from Git with no production clicking.

## Quick start

1. Start your Compose stack (reuse Day-5 Lab 2 or Lab 4 patterns).
2. Export a service account token; set `GRAFANA_URL` / `TF_VAR_grafana_auth`.
3. Apply Terraform for folders/teams: `cd terraform && terraform init && terraform apply`.
4. Confirm provisioned dashboards under `platform/` and `payments/`.

## How to change a dashboard safely

1. Edit the JSON under `dashboards/...` (or export from a **dev** UI, then replace `id` with `null`).
2. Open a pull request - reviewers check queries, units, thresholds, UID stability.
3. Merge → sync files to the Grafana host / config volume.
4. Wait for provisioning rescan (or restart) - confirm UI is read-only (`allowUiUpdates: false`).
5. Never Save in production UI.

## Backup / restore

Run `scripts/backup.sh` (or Lab 4 `backup.ps1`). Practice restore quarterly and write down elapsed minutes.

## Secrets

Tokens and TLS keys stay out of Git. Inject via environment or a secret manager.
