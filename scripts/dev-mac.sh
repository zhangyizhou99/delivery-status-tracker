#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENV_PY="${ROOT_DIR}/.venv/bin/python"
API_PORT="${API_PORT:-8000}"
WEB_PORT="${WEB_PORT:-5173}"
BACKEND_ONLY=0

if [[ "${1:-}" == "--backend-only" ]]; then
  BACKEND_ONLY=1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[error] Missing required command: $1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -e "$1" ]]; then
    echo "[error] Missing required file: $1" >&2
    echo "[hint] Run ./scripts/setup-mac.sh first." >&2
    exit 1
  fi
}

port_in_use() {
  local port="$1"
  lsof -n -P -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
}

cleanup() {
  if [[ -n "${FRONTEND_PID:-}" ]] && kill -0 "${FRONTEND_PID}" >/dev/null 2>&1; then
    kill "${FRONTEND_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${BACKEND_PID:-}" ]] && kill -0 "${BACKEND_PID}" >/dev/null 2>&1; then
    kill "${BACKEND_PID}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT INT TERM

require_cmd curl
require_file "${VENV_PY}"
require_file "${ROOT_DIR}/backend/alembic.ini"

if [[ "${BACKEND_ONLY}" -eq 0 ]]; then
  require_cmd npm
fi

echo "[start] Applying migrations"
(
  cd "${ROOT_DIR}/backend"
  "${VENV_PY}" -m alembic upgrade head
)

if port_in_use "${API_PORT}"; then
  echo "[error] Port ${API_PORT} is already in use." >&2
  echo "[hint] Stop the existing process or run with another port, for example:" >&2
  echo "[hint] API_PORT=8011 WEB_PORT=${WEB_PORT} ./scripts/dev-mac.sh" >&2
  exit 1
fi

echo "[start] Starting backend on :${API_PORT}"
"${VENV_PY}" -m uvicorn app.main:app --app-dir "${ROOT_DIR}/backend" --host 0.0.0.0 --port "${API_PORT}" &
BACKEND_PID=$!

for _ in {1..30}; do
  if curl -fsS "http://127.0.0.1:${API_PORT}/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! kill -0 "${BACKEND_PID}" >/dev/null 2>&1; then
  echo "[error] Backend process exited unexpectedly during startup." >&2
  exit 1
fi

if ! curl -fsS "http://127.0.0.1:${API_PORT}/api/health" >/dev/null 2>&1; then
  echo "[error] Backend health check failed: http://127.0.0.1:${API_PORT}/api/health" >&2
  exit 1
fi

if [[ "${BACKEND_ONLY}" -eq 1 ]]; then
  echo "[ready] Backend: http://localhost:${API_PORT}/docs"
  wait "${BACKEND_PID}"
  exit 0
fi

echo "[start] Starting frontend on :${WEB_PORT}"
(
  cd "${ROOT_DIR}/frontend"
  export VITE_API_URL="http://localhost:${API_PORT}"
  npm run dev -- --host 0.0.0.0 --port "${WEB_PORT}"
) &
FRONTEND_PID=$!

echo "[ready] Web:  http://localhost:${WEB_PORT}"
echo "[ready] API:  http://localhost:${API_PORT}/docs"
echo "[info] Press Ctrl+C to stop both services"

wait "${FRONTEND_PID}"
