#### Failover test (simulate master failure and check promotion)
#!/bin/bash
set -e

echo "Stopping MySQL master to simulate failure..."
docker stop mysql-master

echo "Waiting 30 seconds for Orchestrator to detect failure and promote a new master..."
sleep 30

echo "Current master:"
docker exec orchestrator orchestrator-client -c all-clusters-masters

echo "Checking ProxySQL runtime master hostgroup (0):"
docker exec proxysql mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "SELECT hostname,port,hostgroup_id  FROM mysql_servers WHERE hostgroup_id=0;"

echo "Waiting 30 seconds before master start..."
sleep 30

echo "Starting old MySQL master..."
docker compose start mysql-master

echo "Waiting 30 seconds for master to start and Orchestrator to detect..."
sleep 30

echo "Check replication status on old master:"
docker exec mysql-master mysql -uroot -prootpass123 -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master)"

echo "Check Orchestrator master after recovery:"
docker exec orchestrator orchestrator-client -c all-clusters-masters

