#!/bin/bash
# vim: set ts=4 sw=4 et

# 1. Path Discovery
# Get the absolute path of the directory where this install.sh lives
REPO_DIR=$(dirname "$(realpath "$0")")
SCRIPTS_SRC="$REPO_DIR/scripts"
DEST_DIR="$HOME/.local/bin"

echo "Scripts dir: $SCRIPTS_SRC"

mkdir -p "$DEST_DIR" ~/.config

# Check for symlink flag (-s or --symlink)
USE_SYMLINKS=false
if [[ "$1" == "-s" || "$1" == "--symlink" ]]; then
    USE_SYMLINKS=true
    echo "--- Mode: Symlinking scripts from $SCRIPTS_SRC ---"
else
    echo "--- Mode: Copying scripts from $SCRIPTS_SRC ---"
fi

# 2. Install scripts via absolute path discovery
for script_path in "$SCRIPTS_SRC"/*; do
    # Ensure the glob matched actual files
    [ -e "$script_path" ] || continue
    
    filename=$(basename "$script_path")
    
    if [ "$USE_SYMLINKS" = true ]; then
        # Create absolute symlink (force overwrite)
        ln -sf "$script_path" "$DEST_DIR/$filename"
        echo "Linked: $filename"
    else
        # Standard copy
        cp "$script_path" "$DEST_DIR/$filename"
        chmod +x "$DEST_DIR/$filename"
        echo "Installed: $filename"
    fi
done

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
    sudo chmod 644 "$LOGROTATE_CONF"
else
    echo "Logrotate config already exists at $LOGROTATE_CONF. Skipping."
fi

# 4. Setup passwordless sudo for the occ command
SUDOERS_FILE="/etc/sudoers.d/nextcloud-sa"

if [ ! -f "$SUDOERS_FILE" ]; then
    echo "Creating $SUDOERS_FILE..."
    sudo tee "$SUDOERS_FILE" > /dev/null <<EOF
sa ALL=(www-data) NOPASSWD: /usr/bin/php /var/www/nextcloud/occ *
EOF
else
    echo "Sudoers config already exists at $SUDOERS_FILE. Skipping."
fi
