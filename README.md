# nextcloud-life
Helpers, scripts, orchestration for using Nextcloud at home

## Passwordless OCC

To allow the user sa to run Nextcloud commands as www-data without a password, you need to modify your sudoers configuration.

By targeting the specific command and user, you keep the system secure while removing the friction of password prompts for your automation or maintenance tasks.

### The Configuration Step

1. Open the sudoers editor:
Always use visudo to edit these files. It checks for syntax errors before saving, which prevents you from accidentally locking yourself out of the system.

```
sudo visudo /etc/sudoers.d/nextcloud-sa
```

2. Add the following line:

```
sa ALL=(www-data) NOPASSWD: /usr/bin/php /var/www/nextcloud/occ
```
