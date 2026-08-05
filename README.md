## Quick Start from a Fresh Clone

The verified runtime path is a native Windows environment. Install these prerequisites first:

- PostgreSQL 14-18, accessible at `localhost:5432`
- Python 3.11-3.14, either through the Windows `py.exe` launcher or an interpreter on `PATH`
- Node.js `20.19+` within the 20.x line, or `22.12+`, with npm; Node 21 is outside Vite 8's supported engine range
- Windows PowerShell 5.1 or later
- Git, unless the repository was downloaded as a ZIP archive

The scripts validate runtime versions before installing dependencies. They discover compatible installations automatically and prefer the highest compatible registered PostgreSQL and Python versions. Installation paths do not need to match the author's machine. An incompatible runtime fails early with the detected version and the available override options. This project has been verified with PostgreSQL 16, Python 3.12 and 3.14, Node.js 24.18, and Windows PowerShell 5.1.

Clone the repository and enter its root directory:

```powershell
git clone https://github.com/zhangyizhou99/delivery-status-tracker.git
Set-Location .\delivery-status-tracker
```

1. Install project dependencies and initialize PostgreSQL:

```powershell
.\scripts\setup.ps1
```

On the first run, enter the local PostgreSQL `postgres` administrator password when prompted. The script does not store this password.

2. Start the backend and frontend together:

```powershell
.\scripts\dev.ps1
```

The development script applies Alembic migrations, inserts any missing records from the seed CSV, and starts:

- Web application: `http://localhost:5173`
- API documentation: `http://localhost:8000/docs`
- Health endpoint: `http://localhost:8000/api/health`

Press `Ctrl+C` to stop both services. After the initial setup, daily development only requires `.\scripts\dev.ps1`.

## macOS Quick Start

The PowerShell scripts in `scripts/` are Windows-first. For macOS, use the dedicated shell scripts.

Prerequisites:

- PostgreSQL 14-18 running on `localhost:5432`
- Python 3.11-3.14
- Node.js `20.19+` within the 20.x line, or `22.12+`
- npm with access to a reachable registry

Clone and enter the repository:

```bash
git clone https://github.com/zhangyizhou99/delivery-status-tracker.git
cd delivery-status-tracker
```

1. Run one-time setup:

```bash
./scripts/setup-mac.sh
```

If you need to use a specific registry for this run:

```bash
NPM_REGISTRY=https://registry.npmjs.org/ ./scripts/setup-mac.sh
```

2. Start services:

```bash
./scripts/dev-mac.sh
```

Optional backend-only mode:

```bash
./scripts/dev-mac.sh --backend-only
```

Optional setup mode that skips frontend dependency install:

```bash
./scripts/setup-mac.sh --skip-frontend
```

### Manual Equivalent

If you prefer to run each step manually, use the commands below.

1. Create a virtual environment and install backend dependencies:

```bash
python3 -m venv .venv
./.venv/bin/python -m pip install --upgrade pip
./.venv/bin/python -m pip install -r backend/requirements.txt
```

2. Configure environment variables:

```bash
cp .env.example .env
```

3. Apply database migrations:

```bash
cd backend
../.venv/bin/python -m alembic upgrade head
cd ..
```

4. Seed missing shipment rows from CSV:

```bash
cd backend
../.venv/bin/python -m app.seed
cd ..
```

5. Start backend:

```bash
./.venv/bin/python -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000
```

6. In another terminal, install frontend dependencies and start Vite:

```bash
cd frontend
npm install
npm run dev -- --host 0.0.0.0 --port 5173
```

Endpoints:

- Web: `http://localhost:5173`
- API docs: `http://localhost:8000/docs`
- Health: `http://localhost:8000/api/health`

If `npm install` fails with registry/network errors (for example `ENOTCONN`), retry with an explicit registry:

```bash
npm install --registry https://registry.npmjs.org/
```

## Technology and Scope

- PostgreSQL 14-18, Python 3.11-3.14, FastAPI, SQLAlchemy 2, Alembic, and psycopg 3
- React 19, TypeScript, Vite 8, a compatible Node.js runtime, and Windows PowerShell 5.1+
- pytest, Ruff, Oxlint, TypeScript type checking, and Vite production build checks

The MVP includes a shipment list, lifecycle status updates, sorting, and a local demo reset. It does not currently include authentication, deployment, general shipment CRUD, arbitrary CSV uploads, status filtering, or status history.

## Core API and Data Model

- The `shipments` table contains `id`, a unique `reference`, `customer_name`, a constrained `status`, `created_at`, and `updated_at`.
- `GET /api/shipments` returns shipments and their current statuses.
- `PATCH /api/shipments/{reference}/status` validates and persists a status transition.
- Invalid lifecycle transitions return `409`; invalid request values return `422`.

## Additional Startup Options

Use different local ports or run a startup smoke test only:

```powershell
.\scripts\dev.ps1 -ApiPort 8011 -WebPort 5184
.\scripts\dev.ps1 -SmokeTest
```

If a runtime is not on `PATH`, or the automatic selection needs to be overridden, provide installation paths explicitly:

```powershell
.\scripts\setup.ps1 -PostgresBin 'D:\PostgreSQL\17' -PostgresService 'my-postgresql-service' -PythonExecutable 'D:\Python313\python.exe' -NodeBin 'D:\NodeJS'
.\scripts\dev.ps1 -PostgresBin 'D:\PostgreSQL\17' -PostgresService 'my-postgresql-service' -NodeBin 'D:\NodeJS'
```

`-PostgresBin` accepts either a PostgreSQL installation root or its `bin` directory. `-PythonExecutable` accepts `python.exe` or `py.exe`. `-NodeBin` accepts the directory containing `node.exe` and `npm.cmd`. The corresponding environment variables are `POSTGRES_BIN`, `POSTGRES_SERVICE`, `PYTHON_EXECUTABLE`, and `NODE_BIN`. The service name is only needed when PostgreSQL is not already running and its Windows service cannot be identified automatically.

## Status Lifecycle and Data

```text
created -> picked_up -> in_transit -> delivered
       \          \             \
        +-> failed +-> failed    +-> failed
```

- `delivered` and `failed` are terminal states. A request for the current status returns `200` without performing a write.
- The CSV is an immutable seed baseline, PostgreSQL is the source of truth for persisted state, and React only holds a page snapshot.
- Startup inserts only missing shipment references and never overwrites existing database statuses.
- A real status transition updates `updated_at`; a same-status request does not.

The in-page **Reset statuses** action restores only statuses that differ from the seed baseline. It preserves rows and IDs. Changed rows receive the reset time as `updated_at`, while rows already matching the baseline keep their existing timestamps. The CSV does not contain original timestamps to restore.

To perform a destructive full reset:

```powershell
.\scripts\reset.ps1
```

This command clears the table, resets the identity sequence, and reinserts all 20 records with new timestamps. The in-page reset endpoint is an unauthenticated local demo tool and must not be exposed directly in production. See [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) for the detailed data lifecycle.

## Tests and Quality Checks

Complete the project setup once before running these commands. Backend integration tests use only the `tracker_test` database and apply database migrations automatically.

```powershell
Push-Location backend
./.venv/Scripts/python.exe -m ruff check .
./.venv/Scripts/python.exe -m pytest
./.venv/Scripts/python.exe -m alembic check
Pop-Location

npm.cmd --prefix frontend run lint
npm.cmd --prefix frontend run build
```

Each check has a distinct purpose:

| Check | Current coverage |
| --- | --- |
| `pytest`: status rules (30 cases) | Verifies the allowed next states for all five statuses and exhaustively covers the $5 \times 5$ transition matrix. Cases include normal progression, transition to `failed`, same-status idempotency, and rejection of skipped, backward, and terminal-state transitions. |
| `pytest`: Shipment API (11 cases) | Uses a real PostgreSQL test database to verify empty results, default sorting, last-updated sorting, invalid sort values, status reset, and repeated reset. It also verifies that a valid transition persists and advances `updated_at`, a same-status request performs no write, an invalid transition returns `409` without changing the database, an invalid body returns `422`, and an unknown shipment returns `404`. |
| `pytest`: CSV seed (5 cases) | Accepts valid CSV input and rejects an incorrect header, an unknown status, duplicate references, and blank required fields. Validation errors include the relevant line number. |
| `pytest`: health endpoint (3 cases) | Verifies `200` when the database is available, `503` when it is unavailable, and CORS access for the default local Vite origin. |
| `pytest`: configuration (2 cases) | Verifies that a custom `WEB_PORT` produces matching default CORS origins and that an explicit `CORS_ORIGINS` value always takes precedence. |
| `ruff check` | Statically checks Python imports, common defects, and code conventions, with Python 3.11 as the minimum syntax target. |
| `alembic check` | Compares SQLAlchemy metadata with the latest migration to catch model changes that are missing a database migration. |
| `npm run lint` | Uses Oxlint to detect static issues in the frontend JavaScript, TypeScript, and React code. |
| `npm run build` | Runs `tsc -b` for TypeScript type checking, then verifies that Vite can produce a production build. |

Backend API tests are hard-wired to `tracker_test`, whose name must end in `_test`. The test suite applies migrations and clears shipment data before and after each database test; it never reads from or writes to the development database, `tracker`.

The latest validation completed all 51 backend test cases and every quality command above. Browser validation covered desktop and 390-pixel-wide layouts, persistence, reset, sorting, and updates without a full-page reload. The project does not yet have an aggregate `scripts/test.ps1`; see [PROJECT_LOG.md](PROJECT_LOG.md) for the validation evidence.

## Key Decisions and Tradeoffs

- **Native Windows runtime:** PowerShell avoided the WSL/Docker path that was unavailable during development, at the cost of reduced portability.
- **Synchronous SQLAlchemy:** For a 20-row local demo, synchronous transactions are simpler to implement, test, and explain.
- **Alembic-managed schema:** Migrations own schema versions instead of calling `create_all` at runtime, so development and test databases can reproduce the same structure.
- **Idempotent CSV seed:** Repeated startup does not create duplicate rows or clear status updates already persisted in PostgreSQL.
- **Server-owned rules and row locking:** A client cannot bypass lifecycle rules, and concurrent requests for the same shipment are validated against the latest database state.
- **Update the UI after server confirmation:** The page changes only after the API commits successfully, avoiding an optimistic update that must be rolled back after database rejection.

Detailed requirements, assumptions, architecture, and data lifecycle decisions are recorded in [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md). Actual work, issues, decisions, and validation history are recorded in [PROJECT_LOG.md](PROJECT_LOG.md).

## AI Usage

- **Tool:** GitHub Copilot in VS Code.
- **AI-assisted work:** Copilot assisted with requirements analysis, architecture options, implementation and test drafts, debugging, browser validation, and documentation. Most code, tests, and documentation drafts were generated by or substantially assisted by Copilot; human work focused primarily on direction, decisions, review, and acceptance.
- **Development governance:** Before implementation, I defined the development plan, working rules, factual project log, validation requirements, and the information that had to be maintained throughout the project.
- **Constraints placed on AI:** I required evidence for every completed item, prohibited fabricated test results and claims about unfinished capabilities, required existing changes to be preserved, and required executable checks after significant edits.
- **Requirements and scope:** Within the time box, I prioritized the required vertical slice across the database, API, and UI, and decided which work should remain as follow-up.
- **Business semantics:** I participated in decisions about the fixed CSV seed, lifecycle assumptions, same-status no-op behavior, in-page status reset, command-line full reset, and `updated_at` behavior.
- **Architecture:** Copilot discussed options and tradeoffs with me. I selected or approved the final approach based on the assignment, Windows environment, and live-demo needs. This included native Windows orchestration, Alembic, synchronous SQLAlchemy, idempotent seeding, row locking, and the frontend/backend state boundary.
- **Visual and interaction direction:** After reviewing the running application, I requested changes to the blue-and-white visual direction, information hierarchy, button presentation, spacing, sorting controls, and mobile layout.
- **Review and delivery:** I defined the acceptance criteria, reviewed the automated, browser, and PostgreSQL evidence, decided whether generated work was acceptable, and controlled the final README and public repository contents.
- **AI error and how it was found:** One AI-generated change made the web port configurable but left FastAPI's default CORS origin fixed at port 5173. An isolated-port browser check showed that Vite loaded correctly on port 5184 while API requests were rejected. The fix derives the default local origins from `WEB_PORT`, preserves explicit `CORS_ORIGINS`, and adds a regression test.

## What I Would Do Next

1. Add `scripts/test.ps1` to run the existing quality checks through one command.
2. Protect reset and status mutation operations with authentication and authorization.
3. Add an append-only status history and explicit concurrency tests.
4. Add status filtering, continuous integration, cross-platform startup, and production secret management.