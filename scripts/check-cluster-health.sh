#!/bin/bash

# Health check for Percona Server MySQL Cluster via Docker Compose
# Assumes container names are: mysql-master, mysql-slave1, mysql-slave2

NODES=("mysql-master" "mysql-slave1" "mysql-slave2")
ROOT_USER="root"
ROOT_PASSWORD="rootpass123"

echo "🔍 Starting MySQL Cluster Health Check..."

for NODE in "${NODES[@]}"; do
  echo "➡️  Checking $NODE..."
  
  docker exec "$NODE" mysqladmin ping -u$ROOT_USER -p$ROOT_PASSWORD > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "❌ $NODE is unreachable or not responding to mysqladmin ping"
    continue
  fi
  echo "✅ $NODE is reachable"

  SERVER_ID=$(docker exec "$NODE" mysql -u$ROOT_USER -p$ROOT_PASSWORD -Nse "SELECT @@server_id;")
  READ_ONLY=$(docker exec "$NODE" mysql -u$ROOT_USER -p$ROOT_PASSWORD -Nse "SELECT @@read_only;")

  echo "ℹ️  Server ID: $SERVER_ID, Read-Only: $READ_ONLY"

  REPLICA_STATUS=$(docker exec "$NODE" mysql -u$ROOT_USER -p$ROOT_PASSWORD -e "SHOW REPLICA STATUS\G" 2>/dev/null)

  if [[ -z "$REPLICA_STATUS" ]]; then
    echo "🧠 $NODE is likely the primary (no replica status)"
  else
    IO_RUNNING=$(echo "$REPLICA_STATUS" | grep 'Replica_IO_Running:' | awk '{print $2}')
    SQL_RUNNING=$(echo "$REPLICA_STATUS" | grep 'Replica_SQL_Running:' | awk '{print $2}')
    
    if [[ "$IO_RUNNING" == "Yes" && "$SQL_RUNNING" == "Yes" ]]; then
      echo "✅ Replication healthy on $NODE (IO: $IO_RUNNING, SQL: $SQL_RUNNING)"
    else
      echo "❌ Replication broken on $NODE (IO: $IO_RUNNING, SQL: $SQL_RUNNING)"
    fi
  fi

  echo "------------------------------"
done


echo "== ProxySQL Connection Test:"
docker exec proxysql mysql -h127.0.0.1 -P6033 -uappuser -papppass123 -e "SELECT '✅ ProxySQL OK' as Status;" 2>/dev/null || echo " ❌ ProxySQL connection failed"
echo "------------------------------"
echo "== Master Write Test:"
docker exec mysql-master mysql -h127.0.0.1 -uappuser -papppass123 testdb -e "INSERT INTO test_table (name) VALUES ('Health Check $(date)');" 2>/dev/null && echo "✅ Write test passed" || echo "❌ Write test failed"
echo "------------------------------"
echo "== Slave1 Read Test:"
docker exec mysql-slave1 mysql -h127.0.0.1 -uappuser -papppass123 testdb -e "SELECT COUNT(*) as 'Total Records' FROM test_table;" 2>/dev/null && echo "✅ Read test passed" || echo "❌ Read test failed"
echo "------------------------------"
echo "== Slave2 Read Test:"
docker exec mysql-slave2 mysql -h127.0.0.1 -uappuser -papppass123 testdb -e "SELECT COUNT(*) as 'Total Records' FROM test_table;" 2>/dev/null && echo "✅ Read test passed" || echo "❌ Read test failed"
echo "------------------------------"
echo "== Orchestrator Status:"
curl -s http://localhost:3000/api/status 2>/dev/null | grep -q "OK" && echo "✅ Orchestrator API responding" || echo "❌ Orchestrator not responding"

echo "✅ Health check complete"