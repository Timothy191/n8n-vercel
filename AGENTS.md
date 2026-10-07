# AGENTS.md — n8n-vercel (Palolo)

Containerized [n8n](https://n8n.io/) on Vercel (`framework: "container"`), Vercel project `n8n-vercel`, typically backed by Supabase Postgres. Repo: `Timothy191/n8n-vercel`. Working branch often `Timothy191/palolo`; production deploys from `master`/`main`.

Run all docker/make/compose commands from this directory (never a monorepo parent).

---

## Role & production invariants

- **Role**: workflow runner (portal webhooks, telemetry triggers, Kestra DAG actions).
- **Prod DB**: always `USE_POSTGRES=true` + full `DB_POSTGRESDB_*`. SQLite loses state on container recycle.
- **WEBHOOK_URL**: must be the public production domain in prod. Entrypoint falls back to `https://n8n-vercel-alpha.vercel.app` if unset — do not rely on that silently.
- **Health probes**: hit stable aliases (e.g. `n8n-vercel-alpha.vercel.app`), **never** unique deployment URLs — those 302 through Vercel SSO and break automation (retrospective `ws-20261002-federation-no-sso`).
- **Health path**: `GET /healthz` on `N8N_PORT` (local default `3000`).
- **Telemetry**: keep `N8N_DIAGNOSTICS_ENABLED=false` unless explicitly requested.

---

## Runtime architecture (do not “simplify” away)

| Piece | Contract |
|-------|----------|
| `Dockerfile` | `FROM n8nio/n8n:latest` → install `graceful-fs` → run `patch-n8n-loading.js` → copy `patch-fs.js` + `entrypoint.sh`. Image is unpinned; upgrades can break the loading patch. |
| `entrypoint.sh` | Raises `ulimit`; `NODE_OPTIONS=--require /entrypoint-fs-patch.js`; maps Vercel `PORT` → `N8N_PORT` (else `N8N_PORT` or `5678`); if `USE_POSTGRES=true` sets `DB_TYPE=postgresdb` and **requires** host/db/user/password; else forces SQLite and **unsets** Postgres env; dispatches to upstream `/docker-entrypoint.sh`. |
| `patch-fs.js` | `gracefulify` on `fs` to avoid EMFILE under microVM fd limits. Required on Vercel. |
| `patch-n8n-loading.js` | **Build-time** string replace in n8n `abstract-server.js`: `res.send('n8n is starting up. Please wait')` → HTML loading page. Fail-open (warn, don’t fail build). Re-verify after base-image bumps. |
| `vercel.json` | Container app; no Node build/install. |

Port rule: on Vercel, `PORT` wins. Locally prefer `N8N_PORT=3000` and publish `3000:3000`.

---

## Local commands

```bash
cp .env.example .env.local   # WEBHOOK_URL=http://localhost:3000 for local
make build                   # docker build -t n8n-vercel .
make dev                     # interactive; mounts entrypoint.sh + patch-fs.js
make run / make down / make logs / make shell
make validate                # required files, executable bits, docker build
make up                      # compose default profile
make up-postgres             # compose --profile postgres
./scripts/validate.sh        # fuller checks used by CI
```

**Compose quirk**: in `docker-compose.yml`, the `n8n` service is under profile `postgres` (with `postgres`). Plain `docker compose up -d` does **not** start n8n. Use `make dev`/`make run`, or `docker compose --profile postgres up -d`. Profiles: `postgres`, `postgis`.

---

## Env surface (source of truth: `.env.example`)

Required conceptually: `N8N_PORT`, `WEBHOOK_URL`.

When `USE_POSTGRES=true`: `DB_TYPE=postgresdb`, `DB_POSTGRESDB_HOST`, `DB_POSTGRESDB_DATABASE`, `DB_POSTGRESDB_USER`, `DB_POSTGRESDB_PASSWORD` (port default `5432`).

Optional prod hardening: `N8N_BASIC_AUTH_*`, `N8N_ENCRYPTION_KEY` (e.g. `openssl rand -base64 32`).

Never commit `.env`, `.env.local`, or `.vercel/` (gitignored). Vercel env lives in project settings; CI deploy needs `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.

---

## UI / cold-boot loading page

Custom UI is the startup loading page only (`patch-n8n-loading.js`, design notes in `UI-UX-GUIDE.md`). Match n8n official tokens — do not invent a parallel palette:

- Primary `#ff9b26`, secondary `#ff5873`, bg `#0e0918` / `#1a1a1a`
- CSS vars: `--color--primary`, `--color--secondary`, `--color--background`, etc. (aliases `--color-bg-*` kept for compat)
- Auto-refresh meta every 2s during cold start

---

## CI / git

- Workflows: `.github/workflows/validate.yml` (fast), `ci-cd.yml` (validate → container test → compose test → Trivy → Vercel deploy).
- Triggers include `master`, `main`, `Timothy191/palolo`. **Deploy job only on `master`/`main`.**
- Commits: conventional (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
- Style: 2-space indent (tabs in `Makefile`); shell `#!/bin/sh` POSIX; max line ~120 (`.editorconfig`).
- Keep `entrypoint.sh` and `scripts/validate.sh` executable.

Required paths CI/validate expect: `Dockerfile`, `entrypoint.sh`, `patch-fs.js`, `vercel.json`, `Makefile`, `docker-compose.yml`, `.env.example`, `README.md`, `CONTRIBUTING.md`, `LICENSE`, `.editorconfig`.

---

## Change rules for agents

1. Prefer editing `entrypoint.sh`, patches, `Dockerfile`, and env contracts over adding app frameworks — this is not a Node app repo.
2. After changing entrypoint/DB/port/webhook behavior, run `make validate` and a container boot check against `/healthz`.
3. After touching the loading page or bumping `n8nio/n8n`, confirm `patch-n8n-loading.js` still finds its target string in the image.
4. Do not remove `graceful-fs` / `patch-fs.js` wiring to “clean up” deps.
5. Update this file when contracts change (ports, env, profiles, probe hosts, deploy branches, patch targets).
6. Federation/skill MCP helpers (`acquire_skill`, `search_unified_memory`, …) apply only when those MCPs are attached; they are not required for ordinary repo work here.
)
