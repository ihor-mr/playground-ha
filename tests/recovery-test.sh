#!/bin/bash
set -e

echo "Starting old MySQL master..."
docker compose start mysql-master

echo "Waiting 30 seconds for master to start and Orchestrator to detect..."
sleep 30

echo "Check replication status on old master:"
docker exec mysql-master mysql -uroot -prootpass123 -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master)"

echo "Check Orchestrator master after recovery:"
docker exec orchestrator orchestrator-client -c all-clusters-masters
