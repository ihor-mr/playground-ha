#!/bin/bash

# MySQL Cluster Setup Script
# This script sets up replication and configures the cluster

set -e

echo "Starting MySQL Cluster Setup..."

# Wait for MySQL services to be ready
echo "Waiting for MySQL services to start..."
sleep 10

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

for SLAVE in mysql-slave1 mysql-slave2; do
  echo "Resetting $SLAVE..."
  docker exec $SLAVE mysql -uroot -prootpass123 -e "
    STOP REPLICA;
    RESET REPLICA ALL;
    RESET MASTER;
  "
done

# Configure replication on slaves
echo "Configuring slave1..."
docker exec mysql-slave1 mysql -uroot -prootpass123 -e "
STOP REPLICA;
CHANGE REPLICATION SOURCE TO 
    SOURCE_HOST='mysql-master',
    SOURCE_USER='replicator',
    SOURCE_PASSWORD='replpass123',
    SOURCE_AUTO_POSITION=1;
START REPLICA;
"

echo "Configuring slave2..."
docker exec mysql-slave2 mysql -uroot -prootpass123 -e "
STOP REPLICA;
CHANGE REPLICATION SOURCE TO 
    SOURCE_HOST='mysql-master',
    SOURCE_USER='replicator',
    SOURCE_PASSWORD='replpass123',
    SOURCE_AUTO_POSITION=1;
START REPLICA;
"

echo "Waiting for replication to sync..."
sleep 10

# Check replication status
echo "Checking replication status..."
echo "=== Slave 1 Status ==="
docker exec mysql-slave1 mysql -uroot -prootpass123 -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master)"

echo "=== Slave 2 Status ==="
docker exec mysql-slave2 mysql -uroot -prootpass123 -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master)"

# # Wait for ProxySQL and configure it
echo "Waiting for ProxySQL to start..."
sleep 15

# echo "Initializing Orchestrator database..."
# docker exec orchestrator /usr/local/orchestrator/orchestrator -c redeploy-internal-db || echo "Database initialization completed"

# # Add master to orchestrator
docker exec orchestrator orchestrator-client -c discover -i mysql-master:3306

# # # Add slave to orchestrator
# docker exec orchestrator orchestrator-client -c discover -i mysql-slave1:3306

# # # Add slave to orchestrator
# docker exec orchestrator orchestrator-client -c discover -i mysql-slave2:3306

# # #####
# docker exec -it proxysql mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "
# LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;
# LOAD MYSQL USERS TO RUNTIME; SAVE MYSQL USERS TO DISK;
# LOAD MYSQL QUERY RULES TO RUNTIME; SAVE MYSQL QUERY RULES TO DISK;"

# # Discover topology
# curl -s "http://orchestrator:3000/api/discover/mysql-master/3306" || echo "API discovery for master may have failed"
# sleep 2
# curl -s "http://orchestrator:3000/api/discover/mysql-slave1/3306" || echo "API discovery for master may have failed"
# sleep 2
# curl -s "http://orchestrator:3000/api/discover/mysql-slave2/3306" || echo "API discovery for master may have failed"

echo "Setup completed! Services available at:"
echo "- MySQL Master: localhost:3306"
echo "- MySQL Slave1: localhost:3307" 
echo "- MySQL Slave2: localhost:3308"
echo "- ProxySQL Admin: localhost:6032 (admin/admin)"
echo "- ProxySQL MySQL: localhost:6033 (appuser/apppass123)"
echo "- Orchestrator Web UI: http://localhost:3000"
