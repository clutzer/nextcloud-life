# Nextcloud Life ☁️

A collection of robust shell scripts and configuration templates designed to automate the maintenance, upgrading, and optimization of a self-hosted Nextcloud instance. These tools prioritize security, CLI-first management, and performance tuning.

## 🛠 Features

- **Automated Upgrades:** Seamless CLI-based transitions from core updates to database migrations.
- **Post-Upgrade Fixups:** Automatic resolution of common Nextcloud warnings (missing indices, big int conversions, etc.).
- **Smart Version Logic:** Detects Nextcloud version strings to dynamically adjust maintenance flags (e.g., `--include-expensive`).
- **Developer Mode:** Installer supports `-s` or `--symlink` to link scripts from the git repo to `~/.local/bin`.
- **System Hardening:** Standardized `sudoers` configurations using absolute paths to prevent PATH hijacking.

## 🚀 Installation

1. **Clone the repository:**
   git clone https://github.com/clutzer/nextcloud-life.git
   cd nextcloud-life

2. **Run the installer:**
   - **Standard Install (Copies):**
```
     ./install.sh
```
   - **Developer Install (Symlinks):**
```
     ./install.sh --symlink
```

*The installer configures `/etc/logrotate.d/nextcloud` and `/etc/sudoers.d/nextcloud-sa` automatically.*

## 📜 Script Overview

### nextcloud-upgrade
The primary orchestrator for version jumps.
- **Pre-flight:** Rotates logs via `logrotate -f` for a clean upgrade trace.
- **Phase 1:** Runs the official `updater.phar` (file replacement).
- **Phase 2:** Executes `occ upgrade` (database migrations).
- **Phase 3:** Triggers `nextcloud-post-upgrade-fixups` to resolve environment warnings.

### nextcloud-post-upgrade-fixups
Maintains database integrity and clears caching overhead.
- Adds missing columns, indices, and primary keys.
- **Expensive Repairs:** Automatically appends `--include-expensive` if version >= 28.0.14.
- **Reporting:** Outputs a total execution timer.

### enable-apcu-memcache.sh
An idempotent script to configure APCu as the local memory cache.
- Installs `php-apcu` and enables it for the CLI (`apc.enable_cli=1`).
- Updates `config.php` to utilize `\OC\Memcache\APCu`.

## 🔍 Troubleshooting

### Monitoring Logs
Use the following commands to diagnose issues if the Admin Panel reports errors:

* **View the last 10 errors (JSON filter):**
```
sudo grep '"level":3' /mnt/storage/nextcloud/nextcloud.log | tail -n 10
```
* **Real-time Log Tailing:**
```
occ log:tail -f
```

### Common Error Levels
| Level | Meaning | Action |
| :--- | :--- | :--- |
| 0 - 1 | Debug / Info | General background noise. |
| 2 | Warning | Something to watch, but not critical. |
| 3 | Error | A task failed. Check `nextcloud-post-upgrade-fixups`. |
| 4 | Fatal | The instance or an app has crashed. |

### Resetting the "X Errors in Log" Warning
If you have resolved the underlying issues but the warning persists in the web UI, clear the log file:

```
occ log:manage --clear
```
OR, via system truncate:
```
sudo truncate -s 0 /mnt/storage/nextcloud/nextcloud.log
```

## ⚙️ Configuration Hints

### Sudo Alias
Add this to your `~/.bashrc` to make `occ` feel native:
```
alias occ='sudo -u www-data /usr/bin/php /var/www/nextcloud/occ'
```

### Log Rotation
Logs are managed via `copytruncate` in `/etc/logrotate.d/nextcloud`. This prevents file-handle lockups during the rotation of the `nextcloud.log`.

