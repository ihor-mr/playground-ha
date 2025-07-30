#!/bin/bash

ORCH_CONTAINER="orchestrator"
MYSQL_MASTER="mysql-master:3306"
ALIAS_NAME="mysql-master"

echo "🧪 Checking known clusters..."
docker exec -i $ORCH_CONTAINER orchestrator-client -c clusters || echo "❌ Failed to list clusters"

echo "🧭 Showing topology for $MYSQL_MASTER..."
docker exec -i $ORCH_CONTAINER orchestrator-client -c topology -i "$MYSQL_MASTER" || echo "❌ Topology command failed"

echo "📛 Checking if alias '$ALIAS_NAME' resolves to a cluster..."
if ! docker exec -i "$ORCH_CONTAINER" orchestrator-client -c which-cluster -alias "$ALIAS_NAME"; then
  echo "❌ Alias '$ALIAS_NAME' did not resolve to a cluster. Please ensure the alias exists and discovery was successful."
else
  echo "✅ Alias '$ALIAS_NAME' successfully resolved."
fi

echo "📄 Displaying orchestrator config (partial)..."
docker exec -i $ORCH_CONTAINER cat /etc/orchestrator/orchestrator.conf.json | grep -E '"(MySQLTopologyUser|BackendDB|SQLite3DataFile|ClusterAliasMap)"' || echo "❌ Config keys missing"

echo "🪵 Showing orchestrator logs (last 50 lines)..."
docker logs "$ORCH_CONTAINER" --tail=50

echo "✅ Completed. If alias isn’t resolving, check 'ClusterAliasMap' in orchestrator.conf.json."
