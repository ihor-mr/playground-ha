#!/bin/bash

# Config
OLD_MASTER_HOST="mysql-master"     # hostname or container name
OLD_MASTER_PORT=3306
NEW_MASTER_HOST="mysql-master"     # new master after failover
NEW_MASTER_PORT=3306
REPL_USER="replicator"
REPL_PASS="replpass123"

echo "Stopping replication and resetting..."
docker exec $OLD_MASTER_HOST mysql -uroot -prootpass123 -e "
STOP SLAVE;
RESET SLAVE ALL;
RESET MASTER;
"

echo "Reconfiguring replication to new master $NEW_MASTER_HOST..."
docker exec $OLD_MASTER_HOST mysql -uroot -prootpass123 -e "
CHANGE MASTER TO
  MASTER_HOST='$NEW_MASTER_HOST',
  MASTER_PORT=$NEW_MASTER_PORT,
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION = 1;
START SLAVE;
"

echo "Done. Old master now replicates from $NEW_MASTER_HOST"
