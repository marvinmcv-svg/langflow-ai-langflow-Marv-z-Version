#!/usr/bin/env bash
# Install dependencies (if needed) and run Langflow locally in development mode.
#
#   ./scripts/dev-run.sh
#
# Starts the FastAPI backend and the Vite dev server, then prints the URL to
# open. Ctrl-C stops both.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FRONTEND_DIR="$ROOT_DIR/src/frontend"
BACKEND_PORT="${LANGFLOW_PORT:-7860}"
FRONTEND_PORT="${VITE_PORT:-3000}"

export LANGFLOW_AUTO_LOGIN="${LANGFLOW_AUTO_LOGIN:-true}"

# `accessibility-checker` (dev-only, used by the `a11y:*` scripts) pulls in
# chromedriver, whose postinstall downloads a binary from Google. On a network
# that blocks it the download fails and takes the whole `npm install` with it,
# leaving node_modules without vite. The driver is not needed to build or run
# the app, so skip fetching it unless the caller asks for it.
export CHROMEDRIVER_SKIP_DOWNLOAD="${CHROMEDRIVER_SKIP_DOWNLOAD:-true}"

echo "==> Installing backend dependencies"
uv sync

if [ ! -x "$FRONTEND_DIR/node_modules/.bin/vite" ]; then
  echo "==> Installing frontend dependencies"
  npm install --prefix "$FRONTEND_DIR"
else
  echo "==> Frontend dependencies already installed"
fi

pids=()
cleanup() {
  trap - INT TERM EXIT
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup INT TERM EXIT

echo "==> Starting backend on port $BACKEND_PORT"
uv run uvicorn \
  --factory langflow.main:create_app \
  --host 0.0.0.0 \
  --port "$BACKEND_PORT" \
  --loop asyncio &
pids+=($!)

echo -n "==> Waiting for backend"
for _ in $(seq 60); do
  if curl -sf "http://localhost:$BACKEND_PORT/health" >/dev/null 2>&1; then
    echo " ready"
    break
  fi
  echo -n "."
  sleep 2
done

echo "==> Starting frontend on port $FRONTEND_PORT"
npm start --prefix "$FRONTEND_DIR" &
pids+=($!)

cat <<EOF

  Langflow is starting up.

    UI       http://localhost:$FRONTEND_PORT
    API      http://localhost:$BACKEND_PORT
    Docs     http://localhost:$BACKEND_PORT/docs

  Press Ctrl-C to stop.

EOF

wait
