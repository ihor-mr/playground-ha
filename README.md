# MySQL High Availability Cluster with ProxySQL and Orchestrator

This setup provides a fault-tolerant MySQL cluster using Percona Server, ProxySQL for load balancing, and Orchestrator for automatic failover.

## Architecture

- **3x Percona Server 8.0.42-33**: 1 Master + 2 Read-Only Slaves
- **1x ProxySQL 2.4.8**: Load balancer and connection pooler
- **1x Orchestrator 3.2.6-9**: Automatic failover management

## Directory Structure

```
.
├── docker-compose.yml
├── setup.sh
├── test-cluster.sh
├── README.md
├── init-scripts/
│   └── 01-users.sql
├── mysql-config/
│   ├── master.cnf
│   └── slave.cnf
├── proxysql-config/
│   └── proxysql.cnf
└── orchestrator-config/
    └── orchestrator.conf.json
```

## Quick Start

1. **Clone/create the directory structure** with all configuration files

2. **Start the cluster:**
   ```bash
   docker-compose up -d
   ```

3. **Run the setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

4. **Test the cluster:**
   ```bash
   chmod +x test-cluster.sh
   ./test-cluster.sh
   ```

## Service Endpoints

| Service | Port | Credentials | Purpose |
|---------|------|-------------|---------|
| MySQL Master | 3306 | root/rootpass123 | Direct access to master |
| MySQL Slave1 | 3307 | root/rootpass123 | Direct access to slave1 |
| MySQL Slave2 | 3308 | root/rootpass123 | Direct access to slave2 |
| ProxySQL MySQL | 6033 | appuser/  


