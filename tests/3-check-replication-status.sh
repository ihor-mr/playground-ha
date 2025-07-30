#!/bin/bash

# List of MySQL container names: first is master, rest are slaves
MYSQL_CONTAINERS=("mysql-master" "mysql-slave1" "mysql-slave2")
MYSQL_USER="root"
MYSQL_PASS="rootpass123"

for CONTAINER in "${MYSQL_CONTAINERS[@]}"; do
  echo "=== Checking replication status on $CONTAINER ==="

  docker exec -i "$CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW SLAVE STATUS\G" 2>/dev/null | \
  grep -E "Slave_IO_Running:|Slave_SQL_Running:|Seconds_Behind_Master:" || \
  echo "No replication (this is likely the master node)"

  echo ""
done
