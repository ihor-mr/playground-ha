#!/bin/bash

CONTAINER_NAME="proxysql"
PROXYSQL_HOST="127.0.0.1"
PROXYSQL_PORT="6033"
MYSQL_USER="appuser"
MYSQL_PASSWORD="apppass123"
DATABASE="testdb"
TABLE="test_table"

i=1
while true; do
  echo "▶️ INSERT #$i"
  docker exec -i "$CONTAINER_NAME" mysql -h "$PROXYSQL_HOST" -P "$PROXYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE" -e "
    INSERT INTO $TABLE (name) VALUES ('Test Name $i');
  "

  echo "▶️ SELECT #$i"
  docker exec -i "$CONTAINER_NAME" mysql -h "$PROXYSQL_HOST" -P "$PROXYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE" -e "
    SELECT * from $TABLE limit 3;
  "

  echo "✏️ UPDATE #$i"
  docker exec -i "$CONTAINER_NAME" mysql -h "$PROXYSQL_HOST" -P "$PROXYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE" -e "
    UPDATE $TABLE SET name = CONCAT(name, ' updated') WHERE id = $((RANDOM % i + 1));
  "

  echo "❌ DELETE #$i"
  docker exec -i "$CONTAINER_NAME" mysql -h "$PROXYSQL_HOST" -P "$PROXYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE" -e "
    DELETE FROM $TABLE WHERE id = $((RANDOM % i + 1));
  "

  i=$((i + 1))
  sleep 15
done

