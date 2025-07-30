#!/bin/bash

# === Конфігурація ===
OLD_MASTER_HOST="mysql-master"
OLD_MASTER_PORT=3306
NEW_MASTER_HOST="mysql-slave2"
NEW_MASTER_PORT=3306
REPL_USER="replicator"
REPL_PASSWORD="replpass123"
MYSQL_ROOT_PASSWORD="rootpass123"

echo "[INFO] Resetting old master ($OLD_MASTER_HOST)..."
docker exec -i $OLD_MASTER_HOST mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
STOP SLAVE;
RESET SLAVE ALL;
RESET MASTER;
EOF

echo "[INFO] Getting GTID from new master ($NEW_MASTER_HOST)..."
GTID=$(docker exec -i $NEW_MASTER_HOST mysql -uroot -p$MYSQL_ROOT_PASSWORD -Nse "SELECT @@GLOBAL.gtid_executed;")

echo "[INFO] GTID on new master: $GTID"

echo "[INFO] Configuring old master as replica..."
docker exec -i $OLD_MASTER_HOST mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
CHANGE MASTER TO
  MASTER_HOST='$NEW_MASTER_HOST',
  MASTER_PORT=$NEW_MASTER_PORT,
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASSWORD',
  MASTER_AUTO_POSITION=1
  FOR CHANNEL '';
START SLAVE;
EOF

echo "[INFO] Slave status on old master:"
docker exec -i $OLD_MASTER_HOST mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS\G" | egrep "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master"

echo "[DONE] Old master successfully rejoined as slave."
