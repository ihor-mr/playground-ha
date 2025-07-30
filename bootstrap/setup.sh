#!/bin/bash

# This script sets up replication and configures the cluster

set -e

echo "Starting MySQL Cluster Setup..."

# Function to wait for MySQL to be ready
wait_for_mysql() {
    local host=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    echo "Waiting for MySQL at $host:$port to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker exec mysql-master mysql -h$host -P$port -uroot -prootpass123 -e "SELECT 1" >/dev/null 2>&1; then
            echo "MySQL at $host:$port is ready!"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: MySQL at $host:$port not ready yet..."
        sleep 5
        ((attempt++))
    done
    
    echo "ERROR: MySQL at $host:$port failed to become ready after $max_attempts attempts"
    return 1
}

# Wait for all MySQL instances
wait_for_mysql mysql-master 3306
wait_for_mysql mysql-slave1 3306  
wait_for_mysql mysql-slave2 3306

echo "Setting up replication..."

# Reset slaves first
for SLAVE in mysql-slave1 mysql-slave2; do
  echo "Resetting $SLAVE..."
  docker exec $SLAVE mysql -uroot -prootpass123 -e "
    STOP REPLICA;
    RESET REPLICA ALL;
    RESET MASTER;
  " 2>/dev/null || echo "Reset completed for $SLAVE"
done

# Configure replication on slaves - UNCOMMENTED AND FIXED
echo "Configuring slave1..."
docker exec mysql-slave1 mysql -uroot -prootpass123 -e "
CHANGE REPLICATION SOURCE TO 
    SOURCE_HOST='mysql-master',
    SOURCE_USER='replicator',
    SOURCE_PASSWORD='replpass123',
    SOURCE_AUTO_POSITION=1;
START REPLICA;
"

echo "Configuring slave2..."
docker exec mysql-slave2 mysql -uroot -prootpass123 -e "
CHANGE REPLICATION SOURCE TO 
    SOURCE_HOST='mysql-master',
    SOURCE_USER='replicator',
    SOURCE_PASSWORD='replpass123',
    SOURCE_AUTO_POSITION=1;
START REPLICA;
"

echo "Waiting for replication to sync..."
sleep 15

# Check replication status
echo "Checking replication status..."
echo "=== Slave 1 Status ==="
docker exec mysql-slave1 mysql -uroot -prootpass123 -e "SHOW REPLICA STATUS\G" | grep -E "(Replica_IO_Running|Replica_SQL_Running|Seconds_Behind_Source)"

echo "=== Slave 2 Status ==="
docker exec mysql-slave2 mysql -uroot -prootpass123 -e "SHOW REPLICA STATUS\G" | grep -E "(Replica_IO_Running|Replica_SQL_Running|Seconds_Behind_Source)"

# Wait for ProxySQL and configure it
echo "Waiting for ProxySQL to start..."
sleep 10

# Load ProxySQL configuration - UNCOMMENTED
echo "Loading ProxySQL configuration..."
docker exec proxysql mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "
LOAD MYSQL SERVERS TO RUNTIME; 
SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL USERS TO RUNTIME; 
SAVE MYSQL USERS TO DISK;
LOAD MYSQL QUERY RULES TO RUNTIME; 
SAVE MYSQL QUERY RULES TO DISK;
"

# Add servers to Orchestrator for discovery - UNCOMMENTED
echo "Adding servers to Orchestrator..."
docker exec orchestrator orchestrator-client -c discover -i mysql-master:3306 || echo "Master discovery may have failed, will retry"

# Wait a bit for discovery
sleep 10

# Show final status
echo "=== Final Status Check ==="
echo "Orchestrator clusters:"
docker exec orchestrator orchestrator-client -c clusters || echo "Clusters command failed"

echo "Orchestrator topology:"
docker exec orchestrator orchestrator-client -c topology -i mysql-master:3306 || echo "Topology command failed"

echo "ProxySQL servers:"
docker exec proxysql mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "SELECT hostgroup_id, hostname, port, status FROM mysql_servers;" || echo "ProxySQL query failed"

echo "Setup completed! Services available at:"
echo "- MySQL Master: localhost:3306"
echo "- MySQL Slave1: localhost:3307" 
echo "- MySQL Slave2: localhost:3308"
echo "- ProxySQL Admin: localhost:6032 (admin/admin)"
echo "- ProxySQL MySQL: localhost:6033 (appuser/apppass123)"
echo "- Orchestrator Web UI: http://localhost:3000"