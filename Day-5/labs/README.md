# Day 5 Labs - Automation, APIs & Capstone

Hands-on labs aligned to **Day-5.pptx** (Modules 17–20).

| Lab | Title | Duration | Folder |
|---|---|---|---|
| **Lab 1** | Drive Grafana from the HTTP API | ~20–30 min | [lab-1/STEPS.md](lab-1/STEPS.md) |
| **Lab 2** | Provision Everything From Files | ~20–30 min | [lab-2/STEPS.md](lab-2/STEPS.md) |
| **Lab 3** | Grafana as Terraform Code | ~25–35 min | [lab-3/STEPS.md](lab-3/STEPS.md) |
| **Lab 4** | Harden, Break & Restore | ~25–35 min | [lab-4/STEPS.md](lab-4/STEPS.md) |
| **Capstone** | Observability Stack as Code | plan + homework | [capstone/STEPS.md](capstone/STEPS.md) |

---

## Rule for the day (from the deck)

If you did it twice by hand, it belongs in a file. Prefer declarative provisioning/Terraform in production; use the API for one-offs and CI glue.

---

## Suggested order

Lab 1 (token) → Lab 2 (files) → Lab 3 (Terraform uses the token) → Lab 4 (TLS/backup) → Capstone outline.

---

## Final-day case study

After the labs (or instead of a long capstone build), run the **ShopFront e-commerce** case study:

→ [../case-study/README.md](../case-study/README.md)

Includes architecture diagrams, a runnable Compose stack, RED + SQL dashboards, chaos scripts, and a checkout latency alert.
