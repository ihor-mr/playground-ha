#!/bin/bash

# /usr/local/orchestrator/scripts/proxysql_reconfig.sh
# Arguments: promoted_host promoted_port
NEW_MASTER_HOST=$1
NEW_MASTER_PORT=$2

mysql -uadmin -padmin -h proxysql -P6032 -e "
UPDATE mysql_servers SET status='OFFLINE_SOFT' WHERE host NOT IN ('$NEW_MASTER_HOST');
UPDATE mysql_servers SET status='ONLINE' WHERE host='$NEW_MASTER_HOST';
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
"
