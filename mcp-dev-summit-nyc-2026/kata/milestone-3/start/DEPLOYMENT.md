# Deployment Summary

Linear Clone deployed to a DigitalOcean droplet using Docker Compose.

**Live URL: http://159.65.255.69**

---

## Architecture

```
Browser
  └── :80  nginx (frontend container)
              ├── /          → serves Vite-built React SPA
              └── /api/*     → proxies to backend:3001
                                └── Express API
                                      └── Postgres (db container)
```

All three services run as Docker containers on a single droplet, connected via an internal Docker bridge network. Only port 80 is exposed publicly.

---

## Infrastructure

| Field    | Value                        |
|----------|------------------------------|
| Provider | DigitalOcean                 |
| Droplet  | `linear-clone`               |
| Size     | `s-1vcpu-1gb` ($6/mo)        |
| OS       | Ubuntu 22.04 LTS             |
| Region   | nyc3                         |
| IP       | `159.65.255.69`              |
| SSH key  | `~/.ssh/linear-clone-deploy` |

---

## Files Added

| File                          | Purpose                                                                 |
|-------------------------------|-------------------------------------------------------------------------|
| `backend/Dockerfile.prod`     | Multi-stage: compiles TypeScript → runs `node dist/index.js`           |
| `frontend/Dockerfile.prod`    | Multi-stage: Vite build → nginx static server                          |
| `frontend/nginx.conf`         | SPA routing (`try_files`) + `/api/` reverse proxy to backend           |
| `docker-compose.prod.yml`     | Production compose: frontend on port 80, no source volume mounts       |
| `deploy.sh`                   | End-to-end deploy script (see below)                                   |

---

## Deploy Script (`deploy.sh`)

Bootstraps and deploys the app to any Ubuntu droplet in one command:

```bash
./deploy.sh <droplet-ip>
```

**What it does:**

1. **Waits for SSH** — retries up to 30× until the droplet is reachable
2. **Bootstraps Docker** — installs Docker CE + Compose plugin from the official apt repo if not present; waits for any existing `apt` lock to clear using `fuser`
3. **Rsyncs code** — transfers the project to `/opt/linear-clone` on the server (excludes `.git`, `node_modules`, `dist`, `.env`)
4. **Builds & starts** — runs `docker compose -f docker-compose.prod.yml build --no-cache` then `up -d --remove-orphans`

**Requirements (local machine):**
- Docker (for reference only — build happens on the server)
- `rsync`
- SSH access as `root` using `~/.ssh/linear-clone-deploy`

**Re-deploying** (e.g. after a code change): just run `./deploy.sh <droplet-ip>` again. It will rsync the latest code and rebuild the images.

---

## SSH Key Setup

### Key generation

A dedicated ED25519 key pair was generated locally (no passphrase, for scripted use):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/linear-clone-deploy -N "" -C "linear-clone-deploy"
```

This produces two files on the local machine:
- `~/.ssh/linear-clone-deploy` — private key (never leaves the local machine)
- `~/.ssh/linear-clone-deploy.pub` — public key

### Registration with DigitalOcean

The public key was registered at the **DigitalOcean account level** (not project-level — DO does not support project-scoped SSH keys) via the API:

```bash
curl -X POST "https://api.digitalocean.com/v2/account/keys" \
  -H "Authorization: Bearer <DO_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"name": "linear-clone-deploy", "public_key": "<contents of .pub file>"}'
```

This assigned it **account-wide key ID `55325715`**. It now appears under **Settings → Security → SSH Keys** at https://cloud.digitalocean.com/account/security and can be reused on any future droplet in the account.

### Injection into the droplet

When the droplet was provisioned, the key ID was passed in the creation request. DigitalOcean automatically added the public key to `/root/.ssh/authorized_keys` on the droplet, allowing passwordless SSH login:

```bash
ssh -i ~/.ssh/linear-clone-deploy root@159.65.255.69
```

### Removal

To revoke access, delete the key from your account:
- Via the DO control panel: **https://cloud.digitalocean.com/account/security**
- Or via API: `DELETE https://api.digitalocean.com/v2/account/keys/55325715`

Note: deleting the account-level key does **not** remove it from already-provisioned droplets (`authorized_keys` on the server is not retroactively updated). To fully revoke access you would also need to remove the entry from `/root/.ssh/authorized_keys` on the droplet itself.

---

## CRUD Verification

All four operations were verified via Chrome DevTools against the live deployment:

| Operation | Test                                                        | Result |
|-----------|-------------------------------------------------------------|--------|
| Read      | Page load — seed issues SAN-1 and SAN-2 visible            | ✅     |
| Create    | Created "Test CRUD issue from deployment" → SAN-3 appeared | ✅     |
| Update    | Edited SAN-1 title — change persisted after reload         | ✅     |
| Delete    | Deleted SAN-3 via `···` menu → removed from list           | ✅     |

---

## Notes

- The backend auto-runs DB migrations and seeds 2 sample issues on first startup — no manual DB setup needed.
- Postgres data is persisted in a named Docker volume (`pgdata`) and survives container restarts.
- On fresh Ubuntu droplets, `unattended-upgrades` holds the `apt` lock for several minutes after first boot. The deploy script waits for it to clear automatically before installing Docker.
