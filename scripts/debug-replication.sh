#!/bin/bash

echo "=== MySQL Replication Debug ==="

echo "1. Check if all MySQL containers are fully started:"
for container in mysql-master mysql-slave1 mysql-slave2; do
    echo "Testing $container..."
    docker exec $container mysql -uroot -prootpass123 -e "SELECT @@hostname, @@server_id;" 2>/dev/null && echo "✓ $container MySQL ready" || echo "✗ $container MySQL not ready"
done

echo ""
echo "2. Check network connectivity between containers:"
docker exec mysql-slave1 ping -c 2 mysql-master 2>/dev/null && echo "✓ Slave1 can reach master" || echo "✗ Slave1 cannot reach master"
docker exec mysql-slave2 ping -c 2 mysql-master 2>/dev/null && echo "✓ Slave2 can reach master" || echo "✗ Slave2 cannot reach master"

echo ""
echo "3. Test replication user on master:"
docker exec mysql-master mysql -uroot -prootpass123 -e "SELECT User, Host FROM mysql.user WHERE User='replicator';"
docker exec mysql-master mysql -ureplicator -preplpass123 -e "SELECT 'Replication user works' as status;" 2>/dev/null && echo "✓ Replication user OK" || echo "✗ Replication user failed"

echo ""
echo "4. Test replication user from slaves:"
docker exec mysql-slave1 mysql -ureplicator -preplpass123 -hmysql-master -e "SELECT 'Slave1 can connect to master' as status;" 2>/dev/null && echo "✓ Slave1 replication connection OK" || echo "✗ Slave1 cannot connect as replicator"
docker exec mysql-slave2 mysql -ureplicator -preplpass123 -hmysql-master -e "SELECT 'Slave2 can connect to master' as status;" 2>/dev/null && echo "✓ Slave2 replication connection OK" || echo "✗ Slave2 cannot connect as replicator"

echo ""
echo "5. Check master status and GTID:"
echo "Master GTID status:"
docker exec mysql-master mysql -uroot -prootpass123 -e "SHOW MASTER STATUS;"
docker exec mysql-master mysql -uroot -prootpass123 -e "SELECT @@gtid_executed;"

echo ""
echo "6. Detailed slave status:"
echo "=== SLAVE1 DETAILED STATUS ==="
docker exec mysql-slave1 mysql -uroot -prootpass123 -e "SHOW SLAVE STATUS\G" | grep -E "(Master_Host|Master_User|Master_Port|Last_IO_Error|Last_SQL_Error|Slave_IO_Running|Slave_SQL_Running)"

echo ""
echo "=== SLAVE2 DETAILED STATUS ==="
docker exec mysql-slave2 mysql -uroot -prootpass123 -e "SHOW SLAVE STATUS\G" | grep -E "(Master_Host|Master_User|Master_Port|Last_IO_Error|Last_SQL_Error|Slave_IO_Running|Slave_SQL_Running)"

echo ""
echo "7. Check MySQL error logs:"
echo "=== MASTER ERRORS ==="
docker exec mysql-master tail -10 /var/log/mysql/error.log 2>/dev/null | grep -i error || echo "No recent errors in master log"

echo ""
echo "=== SLAVE1 ERRORS ==="
docker exec mysql-slave1 tail -10 /var/log/mysql/error.log 2>/dev/null | grep -i error || echo "No recent errors in slave1 log"

echo ""
echo "=== SLAVE2 ERRORS ==="
docker exec mysql-slave2 tail -10 /var/log/mysql/error.log 2>/dev/null | grep -i error || echo "No recent errors in slave2 log"

echo ""
echo "8. ProxySQL server status:"
docker exec proxysql mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "SELECT hostgroup, srv_host, srv_port, status FROM mysql_servers;" 2>/dev/null || echo "Cannot connect to ProxySQL admin"