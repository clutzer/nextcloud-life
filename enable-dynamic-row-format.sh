#!/bin/bash
# vim: set ts=4 sw=4 et

# After upgrading to Nextcloud 31, it complained about the row format.
CONF_FILE=/etc/mysql/mariadb.conf.d/99-nextcloud-tweaks.cnf
DB_NAME="nextcloud"

# Check for the --alter flag
DRY_RUN=true
if [[ "$1" == "--alter" ]]; then
    DRY_RUN=false
    echo "--- MODE: LIVE ALTER (Changes will be applied) ---"
else
    echo "--- MODE: DRY RUN (No changes will be made. Use --alter to apply) ---"
fi

# 1. Change the default row format for new tables to Dynamic
if [ ! -f "$CONF_FILE" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would create $CONF_FILE and restart MariaDB."
    else
        echo "Creating $CONF_FILE to apply Nextcloud tweaks to the DB..."
        sudo tee "$CONF_FILE" > /dev/null <<EOF
[mysqld]
# Ensure modern Barracuda format for all tables
innodb_file_per_table = 1
innodb_default_row_format = dynamic
innodb_file_format = Barracuda

# Recommended for Nextcloud 31 performance
innodb_large_prefix = 1
EOF
        sudo systemctl restart mariadb || sudo systemctl restart mysql
    fi
fi

# Define the list provided by Nextcloud
TABLE_LIST="oc_richdocuments_assets, oc_passwords_password_rv, oc_users, oc_circles_share_lock, oc_preferences, oc_mail_classifiers, oc_circles_member, oc_cards, oc_activity_mq, oc_circles_remote, oc_systemtag_group, oc_storages, oc_vcategory_to_object, oc_privacy_admins, oc_talk_internalsignaling, oc_accounts, oc_mail_trusted_senders, oc_profile_config, oc_notifications, oc_circles_membership, oc_collres_accesscache, oc_login_flow_v2, oc_activity, oc_files_trash, oc_text_steps, oc_systemtag, oc_bruteforce_attempts, oc_addressbookchanges, oc_flow_checks, oc_group_admin, oc_mail_attachments, oc_systemtag_object_mapping, oc_passwords_password, oc_talk_rooms, oc_mail_message_tags, oc_mail_messages, oc_share_external, oc_cards_properties, oc_properties, oc_passwords_share, oc_circles_mountpoint, oc_passwords_tag_rv, oc_groups, oc_ratelimit_entries, oc_talk_commands, oc_addressbooks, oc_accounts_data, oc_oauth2_access_tokens, oc_calendarobjects_props, oc_directlink, oc_notifications_settings, oc_passwords_tag, oc_calendar_appt_configs, oc_collres_collections, oc_richdocuments_wopi, oc_notifications_pushhash, oc_calendar_resources, oc_talk_attendees, oc_oauth2_clients, oc_comments, oc_passwords_keychain, oc_whats_new, oc_passwords_pw_tag_rel, oc_mail_tags, oc_circles_event, oc_calendarchanges, oc_passwords_registration, oc_twofactor_providers, oc_trusted_servers, oc_mail_provisionings, oc_webauthn, oc_recent_contact, oc_circles_circle, oc_federated_reshares, oc_group_user, oc_mimetypes, oc_authtoken, oc_calendar_appt_bookings, oc_calendarobjects, oc_direct_edit, oc_vcategory, oc_passwords_folder_rv, oc_mail_mailboxes, oc_calendar_reminders, oc_dav_cal_proxy, oc_calendarsubscriptions, oc_jobs, oc_dav_shares, oc_migrations, oc_circles_mount, oc_collres_resources, oc_known_users, oc_share, oc_circles_token, oc_mail_aliases, oc_passwords_folder, oc_authorized_groups, oc_filecache_extended, oc_talk_sessions, oc_mail_accounts, oc_mounts, oc_text_documents, oc_user_transfer_owner, oc_calendar_rooms_md, oc_mail_recipients, oc_calendar_invitations, oc_appconfig, oc_talk_bridges, oc_storages_credentials, oc_passwords_challenge, oc_passwords_session, oc_mail_local_messages, oc_file_locks, oc_calendars, oc_user_status, oc_flow_operations_scope, oc_richdocuments_direct, oc_text_sessions, oc_calendar_rooms, oc_filecache, oc_flow_operations, oc_twofactor_backupcodes, oc_calendar_resources_md, oc_schedulingobjects, oc_comments_read_markers, oc_mail_coll_addresses"

echo "--- Checking Table Row Formats ---"

for table in ${TABLE_LIST//,/ }; do
    # Fetch current format
    CURRENT_FORMAT=$(sudo mysql -N -s -e "SELECT ROW_FORMAT FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='$table';")

    if [ "$CURRENT_FORMAT" != "Dynamic" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[WOULD ALTER] $table (currently $CURRENT_FORMAT)"
        else
            echo "[ALTERING] $table... "
            sudo mysql -e "ALTER TABLE $DB_NAME.$table ROW_FORMAT=DYNAMIC;"
            sudo mysql -e "ANALYZE TABLE $DB_NAME.$table;"
        fi
    else
        echo "[OK] $table is already Dynamic."
    fi
done

echo "--- Process Complete ---"
