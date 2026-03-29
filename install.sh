#!/bin/bash

# 1. Create the directory for your personal scripts
mkdir -p ~/.local/bin ~/.config

# 2. Install scripts into ~/.local/bin
cp scripts/*.sh ~/.local/bin

# 3. Setup Logrotate for Nextcloud
LOGROTATE_CONF="/etc/logrotate.d/nextcloud"

if [ ! -f "$LOGROTATE_CONF" ]; then
    echo "Creating $LOGROTATE_CONF..."
    sudo tee "$LOGROTATE_CONF" > /dev/null <<EOF
/mnt/storage/nextcloud/nextcloud.log {
    su www-data www-data
    copytruncate
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF
    # Set proper permissions for logrotate configs
    sudo chmod 644 "$LOGROTATE_CONF"
else
    echo "Logrotate config already exists at $LOGROTATE_CONF. Skipping."
fi
