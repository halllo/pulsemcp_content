# Milestone 2 — Summary

## What was built

A pixel-accurate Linear issue tracker clone at `/Users/Manuel.Naujoks/linear-clone`, with:

- **React 18 + Vite + TypeScript** frontend (SPA, React Router v6)
- **Express 4 + TypeScript** REST API backend
- **PostgreSQL 16** database, auto-seeded with 5 starter issues (MAN-1…MAN-5)
- **nginx** reverse proxy (serves static assets + proxies `/api/*` to backend)
- **docker-compose** / **podman-compose** container stack

PR: **https://github.com/halllo/linear-clone/pull/1**

---

## Tools used

| Tool | Purpose |
|------|---------|
| Chrome DevTools MCP | Screenshot capture, DOM inspection, scripted E2E testing |
| GitHub MCP | Creating the pull request |
| Podman + podman-compose | Building and running the container stack |
| PostgreSQL (psql) | Verifying database state |

---

## Visual comparison rounds

Five rounds of screenshots were taken comparing the running app against the Figma spec ([linear-clone-figma-spec.md](../../milestone-1/start/linear-clone-figma-spec.md)). Key fixes per round:

1. **Round 1** — Initial layout, sidebar colours, CSS custom properties wired up
2. **Round 2** — Issue row grid positions corrected via explicit `grid-column` placement (matched Figma x-coords: priority=38px, status=66px, ID=133px, title=212px)
3. **Round 3** — Group header, tab bar, page header polish; modal shadow and chip styling
4. **Round 4** — Issue detail breadcrumb, right panel cards (Properties / Labels / Project), activity section, comment box
5. **Round 5** — Final verification pass; all CRUD flows confirmed working

Screenshots saved to `/Users/Manuel.Naujoks/linear-clone/screenshots/`.

---

## CRUD flows tested end-to-end

| Operation | How | Result |
|-----------|-----|--------|
| **List** | App load | All issues grouped by status (Todo, In Progress, Backlog, Done, Cancelled) |
| **Read** | Click any issue row | Full detail view with title, description, activity, right-panel properties |
| **Create** | Press `C` or click `+` in a group header → fill modal → Create issue | New issue (MAN-N) appears instantly in correct status group |
| **Update title/desc** | Edit in-place on detail page (blur saves) | Changes persist on reload |
| **Update status** | Status dropdown in right panel | Status updates immediately, issue moves to correct group on return |
| **Delete** | `···` menu on detail breadcrumb → Delete issue | Issue removed, redirected to issue list |

All six operations were verified via the browser UI with Chrome DevTools scripted automation (`window.confirm` mocked for delete, `evaluate_script` for API calls).

---

## Multi-instance configuration

Each port is driven by an env var:

```bash
# Instance A (defaults)
podman-compose up --build -d
# → http://localhost:3000

# Instance B (custom ports)
FRONTEND_PORT=3010 BACKEND_PORT=3011 DB_PORT=5433 \
  podman-compose --project-name linear-clone-b up --build -d
# → http://localhost:3010
```
