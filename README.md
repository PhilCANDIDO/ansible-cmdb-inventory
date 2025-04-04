# Ansible Role: cmdb_inventory

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This Ansible role automatically collects comprehensive inventory data from Linux servers to populate a CMDB (Configuration Management Database). It is designed to efficiently handle large-scale inventories (up to several thousand servers) and works with most common Linux distributions.

## Features

The role collects the following structured information:

### Hardware Information
- Server model and manufacturer
- Serial number
- Processor type, number of cores/threads
- Total RAM capacity
- Storage (disks, capacities, RAID)
- Network interfaces (count, type, speed)
- Virtualization type (if applicable)

### Software Information
- Linux distribution and version
- Linux kernel
- Number of installed packages
- Running services
- Installed databases

### Network Information
- IP addresses (IPv4/IPv6)
- Hostname and FQDN
- DNS configuration
- Network routes
- Firewall configuration

### Security Information
- Update status
- Configured users (shell accounts, sudo accounts, etc.)
- SELinux/AppArmor
- Certificates and expiration dates
- Detected backup solutions

### Organizational Information
- Server role/function
- Criticality (production, test, development)
- Hosted applications
- Business owner
- Technical administrator
- SLA/support level
- Commissioning date
- Expected end-of-life/replacement date
- Physical location (datacenter, rack, position)

## Optimizations for Large Environments

This role integrates several specific optimizations for managing large server fleets:

- **Incremental inventory mode**: Only collects information likely to have changed
- **Parallelization**: Optimized to work with Ansible's `--forks` option
- **Self-diagnostic**: Pre-checks capability to collect information
- **Robust error handling**: Continues inventory even if some machines are unreachable
- **Flexible formatting**: Output in JSON or YAML according to needs

## Requirements

- Ansible 2.9+
- SSH access to target servers
- Sudo rights on target servers
- Python 2.7+ or Python 3.5+ on target servers
- Required Python libraries:
  - jmespath>=0.10.0 (for json_query filters)
  - netaddr>=0.8.0 (for IP address filtering)
  - packaging>=0.20.0 (for version comparison)

## Installation

### Via Ansible Galaxy

```bash
ansible-galaxy install git+https://github.com/your-username/ansible-cmdb-inventory.git
```

### Manual Installation

1. Clone this repository to your Ansible roles directory:
   ```bash
   git clone https://github.com/your-username/ansible-cmdb-inventory.git /etc/ansible/roles/cmdb_inventory
   ```

2. Install required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Variables

All main variables are defined in `defaults/main.yml` and can be customized:

```yaml
# Directory where reports will be stored on the Ansible server
cmdb_inventory_local_dir: "/opt/cmdb/inventory"

# Temporary directory on targets
cmdb_inventory_remote_dir: "/tmp/cmdb_inventory"

# Desired output format
cmdb_output_format: "json"  # Options: json, yaml

# Clean up temporary files after execution
cmdb_inventory_cleanup: true

# Information to collect
cmdb_collect:
  hardware: true
  software: true
  network: true
  security: true
  organizational: true
  self_diagnostic: true

# Performance parameters for large environments
cmdb_performance:
  incremental_enabled: true
  full_inventory_days: [0]  # Default every Sunday
  min_days_between_full: 7
  max_days_between_full: 30
  async_tasks: true
  async_timeout: 300
```

## Organizational Information

Organizational information can be defined in multiple ways:

1. **In the Ansible inventory** - see the example in `/examples/inventory.ini`
2. **In group_vars or host_vars**
3. **On target servers** - files in `/etc/org_metadata.json` or `/etc/server_*`

## Usage Example

An example playbook is provided in `/examples/cmdb_inventory.yml`.

```bash
# Run on all servers with default inventory
ansible-playbook cmdb_inventory.yml

# Run on a specific group
ansible-playbook cmdb_inventory.yml --limit webservers

# Run with a custom inventory
ansible-playbook -i custom_inventory.ini cmdb_inventory.yml

# Run with custom parameters
ansible-playbook cmdb_inventory.yml -e "cmdb_output_format=yaml cmdb_inventory_local_dir=/tmp/cmdb"
```

## Parallelization for Large Environments

For large environments (several thousand servers), use the `--forks` option to increase parallelization:

```bash
ansible-playbook -i inventory.ini cmdb_inventory.yml --forks=100
```

## Integration with CMDB Solutions

The collected data is structured to facilitate integration with CMDB solutions such as:
- ServiceNow
- iTop
- Device42
- Ralph CMDB

Integration scripts are available in the `/integration` directory.

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for more information.

## License

MIT

## Author

- Philippe CANDIDO ([philippe.candido@cpf-informatique.fr](mailto:philippe.candido@cpf-informatique.fr))