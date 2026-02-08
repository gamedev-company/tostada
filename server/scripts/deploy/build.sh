#!/bin/bash
# Build a production release (client + server)
# Run from: server/ (or anywhere)

set -euo pipefail

APP_NAME=${APP_NAME:-tostada}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
CLIENT_DIR="$PROJECT_ROOT/client"

if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
fi

export MIX_ENV=prod

echo "==> Building ${APP_NAME} release..."

# Build client app first (outputs to priv/static/app)
echo "==> Building client app..."
cd "$PROJECT_ROOT"
npm install --prefix "$CLIENT_DIR"
npm run prebuild --prefix "$CLIENT_DIR"
NODE_ENV=production npm run build --prefix "$CLIENT_DIR"

# Install/update dependencies
cd "$SERVER_DIR"
echo "==> Installing Elixir dependencies..."
mix deps.get --only prod

# Compile first (generates colocated hooks for LiveView)
echo "==> Compiling application..."
mix compile

# Build Phoenix assets (after compile so colocated hooks exist)
echo "==> Building Phoenix assets..."
mix assets.deploy

# Release
echo "==> Creating release..."
mix release --overwrite

echo "==> Build complete!"
echo "Release at: _build/prod/rel/${APP_NAME}"
