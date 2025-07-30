-- Create replication user with mysql_native_password and no SSL requirement
CREATE USER IF NOT EXISTS  'replicator'@'%' IDENTIFIED WITH mysql_native_password BY 'replpass123';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
ALTER USER 'replicator'@'%' REQUIRE NONE;

-- Create orchestrator user with mysql_native_password and no SSL requirement
CREATE USER IF NOT EXISTS  'orchestrator'@'%' IDENTIFIED WITH mysql_native_password BY 'orchpass123';
GRANT SUPER, PROCESS, REPLICATION SLAVE, RELOAD ON *.* TO 'orchestrator'@'%';
GRANT DROP ON *.* TO 'orchestrator'@'%';
GRANT SELECT ON  *.* TO 'orchestrator'@'%';
ALTER USER 'orchestrator'@'%' REQUIRE NONE;

-- Create ProxySQL monitoring user with mysql_native_password and no SSL requirement
CREATE USER IF NOT EXISTS  'monitor'@'%' IDENTIFIED WITH mysql_native_password BY 'monpass123';
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
GRANT SELECT ON performance_schema.replication_connection_status TO 'monitor'@'%';
GRANT SELECT ON performance_schema.replication_applier_status_by_worker TO 'monitor'@'%';
GRANT SELECT ON performance_schema.replication_group_members TO 'monitor'@'%';
GRANT REPLICATION CLIENT ON *.* TO 'monitor'@'%';
ALTER USER 'monitor'@'%' REQUIRE NONE;


-- Create application user for ProxySQL with mysql_native_password and no SSL requirement
CREATE USER IF NOT EXISTS  'appuser'@'%' IDENTIFIED WITH mysql_native_password BY 'apppass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'appuser'@'%';
ALTER USER 'appuser'@'%' REQUIRE NONE;

FLUSH PRIVILEGES;

-- Create test table
USE testdb;
CREATE TABLE test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some test data
INSERT INTO test_table (name) VALUES 
    ('Test Record 1'),
    ('Test Record 2'),
    ('Test Record 3');

CREATE TABLE IF NOT EXISTS heartbeat (
  server_id int unsigned NOT NULL PRIMARY KEY,
  ts timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Enable event scheduler
SET GLOBAL event_scheduler = ON;

-- Create heartbeat event (runs every second)
CREATE EVENT IF NOT EXISTS heartbeat_event
ON SCHEDULE EVERY 1 SECOND
DO
  REPLACE INTO heartbeat (server_id, ts) VALUES (@@server_id, NOW());