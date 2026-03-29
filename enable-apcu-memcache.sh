# 1. Install APCu if not already present
sudo apt update
sudo apt install php8.1-apcu

# 2. Restart Apache so it loads the extension
sudo systemctl restart apache2

# 3. Enable APCu for the CLI (this is the missing piece)
echo "apc.enable_cli=1" | sudo tee /etc/php/8.1/cli/conf.d/99-nextcloud-apcu.ini > /dev/null

# 4. Tell Nextcloud to use APCu for local cache
sudo -u www-data php /var/www/nextcloud/occ config:system:set memcache.local --value '\OC\Memcache\APCu'

# 5. Restart Apache (just in case)
sudo systemctl restart apache2
