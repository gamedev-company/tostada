#!/bin/bash
# Full deployment: pull, build, migrate, restart
# Run from: server/ (or anywhere)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "==> Full deployment starting..."

git fetch origin
# Safer default than a hard reset; adjust for your workflow.
git pull --rebase

"$SCRIPT_DIR/build.sh"
"$SCRIPT_DIR/deploy.sh"

echo "==> Full deployment complete!"
