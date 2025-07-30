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
