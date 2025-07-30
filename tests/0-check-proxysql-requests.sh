#!/bin/bash

# Name of your ProxySQL container
PROXYSQL_CONTAINER="proxysql"

# ProxySQL admin credentials
ADMIN_USER="admin"
ADMIN_PASS="admin"  # default in many setups, change as needed

echo "==== Query Rules ===="
docker exec -i "$PROXYSQL_CONTAINER" mysql -u"$ADMIN_USER" -p"$ADMIN_PASS" -h127.0.0.1 -P6032 -e \
"SELECT rule_id, match_pattern, destination_hostgroup, apply, active FROM mysql_query_rules ORDER BY rule_id;"

echo ""
echo "==== Query Digest (Top 10 Queries) ===="
docker exec -i "$PROXYSQL_CONTAINER" mysql -u"$ADMIN_USER" -p"$ADMIN_PASS" -h127.0.0.1 -P6032 -e \
"SELECT hostgroup, digest_text, count_star FROM stats.stats_mysql_query_digest ORDER BY count_star DESC LIMIT 10;"
