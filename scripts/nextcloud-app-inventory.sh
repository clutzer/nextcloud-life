#!/bin/bash
# Nextcloud App Inventory + Desired-State Config Generator
NC_DIR="/var/www/nextcloud"
OCC="sudo -u www-data php ${NC_DIR}/occ"

echo "=== Nextcloud App Inventory ==="
echo "Current status as of $(date)"
${OCC} app:list --output=plain | column -t -s $'\t'

# Generate/Update desired-state config
CONFIG="$HOME/.config/nextcloud-apps.conf"
echo "# Nextcloud App Desired State Configuration" > "${CONFIG}"
echo "# Format:  app_id = enable|disable|ignore   # comment" >> "${CONFIG}"
echo "# Edit this file, then run 'nextcloud-app-enforce.sh'" >> "${CONFIG}"
echo "" >> "${CONFIG}"

# Add every app with current state as a commented example
${OCC} app:list --output=json | jq -r 'to_entries[] | "\(.key) = \(.value.enabled | if . then "enable" else "disable" end)  # \(.value.version // "core")"' | sort >> "${CONFIG}"

echo ""
echo "✅ Desired-state config created/updated at ${CONFIG}"
echo "   Edit it with: nano ${CONFIG}"
echo "   Then enforce: nextcloud-app-enforce.sh"
