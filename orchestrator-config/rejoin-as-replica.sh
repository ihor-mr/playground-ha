#!/bin/bash

OLD_MASTER_CONTAINER="mysql-master"
MYSQL_USER="root"
MYSQL_PASS="rootpass123"

# Get the current promoted master from orchestrator
NEW_MASTER=$(docker exec orchestrator \
  orchestrator-client -c get-cluster-master -i mysql-master:3306)

# Parse host and port
NEW_MASTER_HOST=$(echo "$NEW_MASTER" | cut -d':' -f1)
NEW_MASTER_PORT=$(echo "$NEW_MASTER" | cut -d':' -f2)

echo "[INFO] New master is: $NEW_MASTER_HOST:$NEW_MASTER_PORT"

# Skip if old master is already replicating
REPL_STATUS=$(docker exec $OLD_MASTER_CONTAINER \
  mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW SLAVE STATUS\G" 2>/dev/null)

if echo "$REPL_STATUS" | grep -q "Slave_IO_State"; then
  echo "[INFO] $OLD_MASTER_CONTAINER is already a replica. Skipping rejoin."
  exit 0
fi

# Rejoin old master as replica
echo "[IN]()
