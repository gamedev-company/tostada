#!/bin/bash
# Initial server setup (systemd + nginx templates)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo cp "$SCRIPT_DIR/systemd.service" /etc/systemd/system/tostada.service
sudo systemctl daemon-reload
sudo systemctl enable tostada

sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/tostada
sudo ln -sf /etc/nginx/sites-available/tostada /etc/nginx/sites-enabled/tostada

echo "==> Templates installed. Customize service paths and server_name before restarting nginx."
