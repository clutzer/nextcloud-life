#!/bin/bash

# 1. Install APCu if not already present
# -y ensures the script doesn't pause for user input
sudo apt update && sudo apt install -y php8.1-apcu

# 2. Enable APCu for the CLI (The 99-priority override)
# This prevents conffile conflicts during future package updates
echo "apc.enable_cli=1" | sudo tee /etc/php/8.1/cli/conf.d/99-nextcloud-apcu.ini > /dev/null

# 3. Restart Apache so it loads the extension
sudo systemctl restart apache2

# 4. Tell Nextcloud to use APCu for local cache and locking (only if not already set)
CURRENT_CACHE=$(sudo -u www-data php /var/www/nextcloud/occ config:system:get memcache.local 2>/dev/null)
if [ "$CURRENT_CACHE" != "\OC\Memcache\APCu" ]; then
    sudo -u www-data php /var/www/nextcloud/occ config:system:set memcache.local --value '\OC\Memcache\APCu'
fi

CURRENT_LOCKING=$(sudo -u www-data php /var/www/nextcloud/occ config:system:get memcache.locking 2>/dev/null)
if [ "$CURRENT_LOCKING" != "\OC\Memcache\APCu" ]; then
    sudo -u www-data php /var/www/nextcloud/occ config:system:set memcache.locking --value '\OC\Memcache\APCu'
fi

# 5. Verification Block
echo
echo "--- Verification ---"

# Check local cache status
CACHE_VAL=$(sudo -u www-data php /var/www/nextcloud/occ config:system:get memcache.local 2>/dev/null)
if [ "$CACHE_VAL" == "\OC\Memcache\APCu" ]; then
    if [ "$CURRENT_CACHE" == "$CACHE_VAL" ]; then
        echo "✔ Nextcloud was already using memcache (APCu)"
    else
        echo "✔ Nextcloud is now using memcache (APCu)"
    fi
else
    echo "✘ Nextcloud is not using memcache! (APCu)"
fi

# Check locking status
LOCK_VAL=$(sudo -u www-data php /var/www/nextcloud/occ config:system:get memcache.locking 2>/dev/null)
if [ "$LOCK_VAL" == "\OC\Memcache\APCu" ]; then
    if [ "$CURRENT_LOCKING" == "$LOCK_VAL" ]; then
        echo "✔ Nextcloud was already using APCu for transactional locking"
    else
        echo "✔ Nextcloud is now using APCu for transactional locking"
    fi
else
    echo "✘ Nextcloud is not using APCu for transactional locking!"
fi

# Run the integrity check and handle the silent output
sudo -u www-data php /var/www/nextcloud/occ check
if [ $? -eq 0 ]; then
    echo "✔ Nextcloud check passed (Silent Success)"
else
    echo "✘ Nextcloud check failed. Please review logs."
fi

# 6. Dump the status
echo
echo "--- Nextcloud System Status ---"
sudo -u www-data php /var/www/nextcloud/occ status
