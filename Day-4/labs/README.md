# Day 4 Labs - Security, Administration & Best Practices

Hands-on labs aligned to **Day-4.pptx** (Modules 13–16).

| Lab | Title | Duration | Folder |
|---|---|---|---|
| **Lab 1** | Users, Teams & Folder RBAC | ~20–30 min | [lab-1/STEPS.md](lab-1/STEPS.md) |
| **Lab 2** | Version, Export, Import & Provision | ~25–35 min | [lab-2/STEPS.md](lab-2/STEPS.md) |
| **Lab 3** | Capstone - Secure, Govern & Tune | ~45–60 min | [lab-3/STEPS.md](lab-3/STEPS.md) |

---

## Day 4 roadmap (from the deck)

1. User Management (orgs, teams, roles, folder permissions)
2. Authentication & Authorization (local, LDAP, OAuth/OIDC, SSO)
3. Dashboard Management (versioning, import/export, provisioning, GitOps)
4. Performance Optimization (queries, refresh, caching)

---

## Stack

Lab 2 and Lab 3 ship Compose stacks (Grafana + Prometheus). Lab 1 can use any running Grafana admin session from Day 2/3 or Lab 2.

```bash
cd labs/lab-2
docker compose up -d
```

---

## Suggested order

1. Lab 1 (RBAC) → Lab 2 (as-code) → Lab 3 (capstone combines A–E)
2. Use a **second browser / private window** when testing Viewer logins
