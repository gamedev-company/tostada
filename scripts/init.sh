#!/bin/bash
# Initialize the boilerplate into a new app name.

set -euo pipefail

APP_NAME=${APP_NAME:-}
APP_MODULE=${APP_MODULE:-}
APP_HUMAN=${APP_HUMAN:-}
APP_HOST=${APP_HOST:-}

if [ -z "$APP_NAME" ] || [ -z "$APP_MODULE" ]; then
  echo "Usage: make new APP_NAME=my_app APP_MODULE=MyApp [APP_HUMAN='My App'] [APP_HOST=example.com]"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OLD_APP_NAME="tostada"
OLD_MODULE="Tostada"
OLD_WEB_MODULE="TostadaWeb"
NEW_WEB_MODULE="${APP_MODULE}Web"

if [ -z "$APP_HUMAN" ]; then
  APP_HUMAN="$APP_MODULE"
fi

export ROOT_DIR OLD_APP_NAME OLD_MODULE OLD_WEB_MODULE NEW_WEB_MODULE APP_NAME APP_MODULE APP_HUMAN APP_HOST

# Rename key directories/files
if [ -d "$ROOT_DIR/server/lib/$OLD_APP_NAME" ]; then
  mv "$ROOT_DIR/server/lib/$OLD_APP_NAME" "$ROOT_DIR/server/lib/$APP_NAME"
fi
if [ -d "$ROOT_DIR/server/lib/${OLD_APP_NAME}_web" ]; then
  mv "$ROOT_DIR/server/lib/${OLD_APP_NAME}_web" "$ROOT_DIR/server/lib/${APP_NAME}_web"
fi
if [ -f "$ROOT_DIR/server/lib/${OLD_APP_NAME}.ex" ]; then
  mv "$ROOT_DIR/server/lib/${OLD_APP_NAME}.ex" "$ROOT_DIR/server/lib/${APP_NAME}.ex"
fi
if [ -f "$ROOT_DIR/server/lib/${OLD_APP_NAME}_web.ex" ]; then
  mv "$ROOT_DIR/server/lib/${OLD_APP_NAME}_web.ex" "$ROOT_DIR/server/lib/${APP_NAME}_web.ex"
fi
if [ -d "$ROOT_DIR/server/test/${OLD_APP_NAME}_web" ]; then
  mv "$ROOT_DIR/server/test/${OLD_APP_NAME}_web" "$ROOT_DIR/server/test/${APP_NAME}_web"
fi

# Replace text in project files
python3 - <<'PY'
from pathlib import Path
import os

root = Path(os.environ["ROOT_DIR"])
old_app = os.environ["OLD_APP_NAME"]
new_app = os.environ["APP_NAME"]
old_module = os.environ["OLD_MODULE"]
new_module = os.environ["APP_MODULE"]
old_web = os.environ["OLD_WEB_MODULE"]
new_web = os.environ["NEW_WEB_MODULE"]
old_human = "Tostada"
new_human = os.environ.get("APP_HUMAN", "")
old_host = "example.com"
new_host = os.environ.get("APP_HOST", "")

extensions = {".ex", ".exs", ".heex", ".eex", ".js", ".ts", ".json", ".md", ".sh", ".yml", ".yaml", ".toml", ".css", ".html"}

skip_dirs = {".git", "_build", "deps", "node_modules", "priv/static", ".svelte-kit"}

for path in root.rglob("*"):
    if not path.is_file():
        continue
    if path.suffix not in extensions:
        continue
    if any(part in skip_dirs for part in path.parts):
        continue

    data = path.read_text()
    new = data
    new = new.replace(old_web, new_web)
    new = new.replace(old_module, new_module)
    new = new.replace(f":{old_app}", f":{new_app}")
    new = new.replace(old_app, new_app)
    if new_host:
        new = new.replace(old_host, new_host)
    if new_human:
        new = new.replace(old_human, new_human)

    if new != data:
        path.write_text(new)
PY

echo "Initialized project to $APP_MODULE ($APP_NAME)."
