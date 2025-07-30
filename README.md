# MySQL High Availability Cluster with ProxySQL and Orchestrator

This setup provides a fault-tolerant MySQL cluster using Percona Server, ProxySQL for load balancing, and Orchestrator for automatic failover.

## Architecture

- **3x Percona Server 8.0.42-33**: 1 Master + 2 Read-Only Slaves
- **1x ProxySQL 2.4.8**: Load balancer and connection pooler
- **1x Orchestrator 3.2.6-9**: Automatic failover management

## Quick Start

1. **Clone/create the directory structure** with all configuration files

2. **Start the cluster:**
   ```bash
   docker-compose up -d
   ```

3. **Run the setup script that create the cluster:**
   ```bash
   ./bootstrap/setup.sh
   ```

4. **Test the cluster:**
- Below script shutdown the cluster for 30 seconds to show that master failure and slave is promoted automatically
   ```bash
   ./tests/1-master-stop-start.sh
   ```
- Below script on master recovery rejoins as slave. It can be done maybe with hooks but for the test puruses implemented like this
   ```bash
   ./tests/2-rejoin-old-master.sh
   ```
