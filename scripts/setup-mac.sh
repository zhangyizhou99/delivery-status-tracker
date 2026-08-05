#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENV_PY="${ROOT_DIR}/.venv/bin/python"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmjs.org/}"
SKIP_FRONTEND=0

if [[ "${1:-}" == "--skip-frontend" ]]; then
  SKIP_FRONTEND=1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[error] Missing required command: $1" >&2
    exit 1
  fi
}

check_runtime() {
  require_cmd python3
  require_cmd node
  require_cmd npm
  require_cmd curl
}

setup_python() {
  if [[ ! -x "${VENV_PY}" ]]; then
    echo "[setup] Creating Python virtual environment"
    python3 -m venv "${ROOT_DIR}/.venv"
  fi

  echo "[setup] Installing backend Python dependencies"
  "${VENV_PY}" -m pip install --upgrade pip
  "${VENV_PY}" -m pip install -r "${ROOT_DIR}/backend/requirements.txt"
}

setup_env_file() {
  if [[ ! -f "${ROOT_DIR}/.env" ]]; then
    echo "[setup] Creating .env from .env.example"
    cp "${ROOT_DIR}/.env.example" "${ROOT_DIR}/.env"
  fi
}

migrate_and_seed() {
  echo "[setup] Applying Alembic migrations"
  (
    cd "${ROOT_DIR}/backend"
    "${VENV_PY}" -m alembic upgrade head
  )

  echo "[setup] Seeding missing shipments from CSV"
  (
    cd "${ROOT_DIR}/backend"
    "${VENV_PY}" -m app.seed
  )
}

check_npm_reachability() {
  if curl -Is --max-time 8 "${NPM_REGISTRY}" >/dev/null 2>&1; then
    return 0
  fi

  echo "[warn] npm registry is not reachable: ${NPM_REGISTRY}"
  echo "[warn] You can still run backend-only with scripts/dev-mac.sh --backend-only"
  return 1
}

setup_frontend() {
  if [[ "${SKIP_FRONTEND}" -eq 1 ]]; then
    echo "[setup] Skipping frontend install (--skip-frontend)"
    return 0
  fi

  check_npm_reachability || return 1

  echo "[setup] Installing frontend dependencies"
  (
    cd "${ROOT_DIR}/frontend"
    npm install --registry "${NPM_REGISTRY}"
  )
}

print_success() {
  echo ""
  echo "[done] macOS setup completed"
  echo "[next] Start both services: ./scripts/dev-mac.sh"
  echo "[next] Start backend only: ./scripts/dev-mac.sh --backend-only"
  echo "[note] Override npm registry for this setup run only:"
  echo "[note] NPM_REGISTRY=https://registry.npmjs.org/ ./scripts/setup-mac.sh"
}

check_runtime
setup_python
setup_env_file
migrate_and_seed
setup_frontend || true
print_success
