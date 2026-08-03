# Lab 1 - Users, Teams & Folder RBAC

**Course:** Grafana Monitoring & Observability - Day 4  
**Module:** User Management (Hands-on Lab 13)  
**Duration:** ~20–30 minutes

---

## Objectives

1. Create local users and teams
2. Create folders `Production` and `Sandbox`
3. Set folder permissions so Dev is read-only on Production
4. Verify with a real Viewer login

---

## Prerequisites

- Grafana running on http://localhost:3000 with Admin login
- Prefer starting Day-4 Lab 2 stack if nothing is up:

```bash
cd ../lab-2
docker compose up -d
```

Use a **private/incognito window** for the second user.

---

## Identity model reminder

```
Server Admin (all orgs)
  └── Organization
        ├── Users (one role per org: Viewer / Editor / Admin)
        ├── Teams (grant folder permissions here)
        └── Folders → Dashboards
```

**Rule:** Grant to **Teams**, not individuals. Permissions are additive; Org Admin always wins - test with **Viewer** org role.

---

## Step 1 - Create two local users

**Administration → Users and access → Users → New user** (wording may be Admin → Users)

| Login | Email | Password | Org role |
|---|---|---|---|
| `dev.user` | `dev.user@corp.io` | `ChangeMe1!` | **Viewer** |
| `sre.user` | `sre.user@corp.io` | `ChangeMe1!` | **Editor** |

> Do **not** make these users Org Admin or the folder ACL test will be meaningless.

---

## Step 2 - Create two teams

**Administration → Teams → New team**

1. Team name: `Team-Dev` - add member `dev.user`
2. Team name: `Team-SRE` - add member `sre.user`

---

## Step 3 - Create folders

**Dashboards → New → New folder**

1. `Production`
2. `Sandbox`

Optional: create a throwaway dashboard in each folder so permissions are obvious when browsing.

---

## Step 4 - Set folder permissions

Open folder **Production → Folder actions / Manage permissions** (gear on folder).

1. **Remove** the default **Editor** (and tighten Viewer if present on sensitive folders)
2. Add **Team-SRE** → permission **Admin**
3. Add **Team-Dev** → permission **View**

For **Sandbox**:

1. Allow **Team-Dev** → **Edit** (and/or keep Editor so sandbox stays writable)

---

## Step 5 - Test with real logins

### As `dev.user`

1. Private window → login `dev.user`
2. Open **Production** dashboards → can view
3. Confirm **Save** is unavailable / edit blocked
4. Confirm **Sandbox** is editable (if you granted Edit)

### As `sre.user`

1. Can edit Production content
2. Can manage Production folder permissions

### Team change drill

1. As admin, remove `dev.user` from `Team-Dev`
2. Re-login as `dev.user` → Production access should disappear (or lose the team-granted path)

---

## Success criteria

- [ ] `dev.user` sees Production read-only
- [ ] `sre.user` can edit / manage Production
- [ ] Removing user from Team-Dev removes their team-based access
- [ ] You did **not** leave a blanket Editor grant that overrides the design

---

## Watch outs (from the deck)

- Default **Editor** entry on a folder overrides your careful team rule
- Org role **Admin** always wins - test with Viewer
- Permissions are additive (most permissive match applies)
- Deleting a team does not delete its users

---

## Optional - OAuth config sketch (Module 14)

Lab time usually cannot complete a full GitHub OAuth registration. Review and optionally paste into a mounted `grafana.ini` later:

```ini
[auth.github]
enabled = true
client_id = YOUR_CLIENT_ID
client_secret = YOUR_CLIENT_SECRET
scopes = user:email,read:org
auth_url = https://github.com/login/oauth/authorize
token_url = https://github.com/login/oauth/access_token
api_url = https://api.github.com/user
allowed_organizations = your-org
allow_sign_up = true
role_attribute_path = contains(groups[*], '@your-org/platform') && 'Admin' || 'Viewer'
```

Callback URL for local labs: `http://localhost:3000/login/github`  
Keep local admin as break-glass.

See sample file: [`../lab-2/grafana/auth-github.ini.example`](../lab-2/grafana/auth-github.ini.example) (created with Lab 2 files).

---

## Next lab

**[Lab 2 - Version, Export, Import & Provision](../lab-2/STEPS.md)**
