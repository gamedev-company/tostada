#!/bin/bash
# Deploy a built release using systemd
# Run from: server/ (or anywhere)

set -euo pipefail

APP_NAME=${APP_NAME:-tostada}
APP_MODULE=${APP_MODULE:-Tostada}
SERVICE_NAME=${SERVICE_NAME:-$APP_NAME}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
REL_DIR="$SERVER_DIR/_build/prod/rel/$APP_NAME"

if [ -f "$SERVER_DIR/.env" ]; then
  set -a
  source "$SERVER_DIR/.env"
  set +a
fi

echo "==> Deploying ${APP_NAME}..."

# Stop the service
sudo systemctl stop "$SERVICE_NAME" || true

# Run migrations
"$REL_DIR/bin/$APP_NAME" eval "${APP_MODULE}.Release.migrate()"

# Optional seeds
if [ "${RUN_SEEDS:-false}" = "true" ]; then
  "$REL_DIR/bin/$APP_NAME" eval "${APP_MODULE}.Release.seed()"
fi

# Start the service
sudo systemctl start "$SERVICE_NAME"

echo "==> Deployment complete!"
echo "Check status with: sudo systemctl status $SERVICE_NAME"
