# Delivery Status Tracker

A small end-to-end shipment tracker for the TransVirtual full-stack take-home assignment. It imports the supplied 20-row CSV into PostgreSQL and supports validated status updates from a React UI without page reloads.

## Stack and Scope

- PostgreSQL 16, Python 3.12, FastAPI, SQLAlchemy 2, Alembic, and psycopg 3
- React 19, TypeScript, Vite, and Windows PowerShell 5.1
- pytest, Ruff, Oxlint, TypeScript, and Vite build checks

The MVP includes listing, lifecycle updates, sorting, and local demo reset. It excludes authentication, deployment, shipment CRUD, arbitrary CSV upload, and status history.

## Prerequisites

This repository's verified setup path is Windows native. Install:

- PostgreSQL 16 in `C:\Program Files\PostgreSQL\16`, with the `postgresql-x64-16` Windows service
- Python 3.12 with the Windows `py.exe` launcher
- Node.js 24 and npm
- Windows PowerShell 5.1

PostgreSQL must listen on `localhost:5432`. The scripts use local `tracker` and `tracker_test` databases with demo-only credentials.

## Setup and Run

From the repository root, install dependencies and initialize the databases:

```powershell
./scripts/setup.ps1
```

On first use, setup securely prompts for the local PostgreSQL administrator password. It is idempotent and does not store that password.

Start the API and UI:

```powershell
./scripts/dev.ps1
```

This applies migrations, performs an idempotent seed, and starts:

- Web UI: `http://localhost:5173`
- API documentation: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/api/health`

Press `Ctrl+C` to stop both services. Optional startup modes:

```powershell
./scripts/dev.ps1 -ApiPort 8011 -WebPort 5184
./scripts/dev.ps1 -SmokeTest
```

## Lifecycle and Data

```text
created -> picked_up -> in_transit -> delivered
       \          \             \
        +-> failed +-> failed    +-> failed
```

- `delivered` and `failed` are terminal; same-status requests are `200` no-ops.
- The CSV is the immutable baseline, PostgreSQL is the persistent source of truth, and React holds only a page snapshot.
- Startup inserts missing references but never overwrites existing state.
- Real status changes update `updated_at`; no-ops do not.

The UI's **Reset statuses** action restores only changed statuses. It preserves rows and IDs; changed rows receive the reset time as `updated_at`, while already-matching rows keep their timestamp. The CSV contains no original timestamps to restore.

For a destructive full reset:

```powershell
./scripts/reset.ps1
```

This truncates the table, restarts identity, and reinserts all 20 rows with new timestamps. The UI reset endpoint is unauthenticated local tooling and must not be exposed directly in production. See [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) for the detailed data lifecycle.

## Tests and Quality Checks

Run setup once first. Backend integration tests use only `tracker_test` and apply migrations automatically.

```powershell
Push-Location backend
./.venv/Scripts/python.exe -m ruff check .
./.venv/Scripts/python.exe -m pytest
./.venv/Scripts/python.exe -m alembic check
Pop-Location

npm.cmd --prefix frontend run lint
npm.cmd --prefix frontend run build
```

Latest result: 51 backend tests passed; all listed checks passed. Browser verification covered desktop and 390 px layouts, persistence, reset, sorting, and no full-page navigation. There is not yet an aggregate `scripts/test.ps1`; see [PROJECT_LOG.md](PROJECT_LOG.md) for evidence.

## Key Decisions and Trade-offs

- **Windows native:** PowerShell avoided an unavailable WSL/Docker path, trading away portability.
- **Synchronous SQLAlchemy:** simpler transactions are appropriate for this 20-row demo.
- **Alembic only:** migrations, not runtime `create_all`, own the schema.
- **Idempotent seed:** startup cannot erase status changes already in PostgreSQL.
- **Server-owned rules and row locks:** clients cannot bypass transitions, and concurrent requests validate current state.
- **Pessimistic UI updates:** the page changes only after the API commits successfully.

Detailed requirements, assumptions, architecture, and data lifecycle are documented in [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md). The factual work, issue, decision, and validation history is in [PROJECT_LOG.md](PROJECT_LOG.md).

## What I Would Do Next

1. Add `scripts/test.ps1` and rehearse the README from a clean environment.
2. Protect reset and mutations with authentication and authorization.
3. Add append-only status history and explicit concurrency tests.
4. Add status filtering, CI, cross-platform setup, and production secret management.