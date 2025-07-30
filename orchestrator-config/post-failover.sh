#!/bin/bash

# === Input Arguments ===
OLD_MASTER="$1"  # e.g. mysql-master:3306
NEW_MASTER="$2"  # e.g. mysql-slave2:3306
ORCHESTRATOR_CLIENT="orchestrator-client"

if [[ -z "$OLD_MASTER" || -z "$NEW_MASTER" ]]; then
  echo "[ERROR] Usage: $0 <old_master_host:port> <new_master_host:port>"
  exit 1
fi

echo "[INFO] Reconfiguring $OLD_MASTER to replicate from $NEW_MASTER..."

# === Step 0: Forget old master from Orchestrator topology ===
echo "[INFO] Forgetting old master from Orchestrator topology..."
$ORCHESTRATOR_CLIENT -c forget -i "$OLD_MASTER"

# === Step 1: Stop and reset replication on old master ===
echo "[INFO] Stopping replication on old master..."
$ORCHESTRATOR_CLIENT -c stop-replica -i "$OLD_MASTER"

echo "[INFO] Resetting replication source on old master..."
$ORCHESTRATOR_CLIENT -c reset-replica -i "$OLD_MASTER"

# === Step 2: Discover both instances in Orchestrator ===
echo "[INFO] Re-discovering both instances in orchestrator..."
$ORCHESTRATOR_CLIENT -c discover -i "$NEW_MASTER"
$ORCHESTRATOR_CLIENT -c discover -i "$OLD_MASTER"

# === Step 3: Attach old master as replica of new master ===
echo "[INFO] Reattaching old master as replica of new master..."
$ORCHESTRATOR_CLIENT -c reattach-replica-master-host -i "$OLD_MASTER" -d "$NEW_MASTER"

# === Step 4: Start replication on old master ===
echo "[INFO] Starting replication on old master..."
$ORCHESTRATOR_CLIENT -c start-replica -i "$OLD_MASTER"

# === Step 5: Check replication lag ===
echo "[INFO] Checking replication lag on old master:"
$ORCHESTRATOR_CLIENT -c which-heuristic-lag -i "$OLD_MASTER"

echo "[DONE] Old master successfully rejoined as replica."
