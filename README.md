# Guacamole Access Setup

This project provides an automated setup for Apache Guacamole using Docker Compose with configurable credentials.

## Quick Start

### Installing prerequisites
We need at least `docker` for container management and `xrdp` for remote desktop view.
```bash
./install-prerequisites.sh
```

### Default Setup
```bash
./prepare.sh
```

### Custom Configuration
```bash
# Using command line arguments
./prepare.sh -r 'myRootPass123!' -d 'myguacdb' -p 'myUserPass456!'

# Using a configuration file
cp config.env.example config.env
# Edit config.env with your values
./prepare.sh -c config.env
```

### Cleanup
If you want to uninstall everyting, run:
```bash
./cleanup.sh
```

### Access Guacamole
- Open your browser to: http://localhost:8080/guacamole
- Default credentials: `guacadmin` / `guacadmin`

## Configuration Options

The script accepts the following parameters:

| Option | Description | Default |
|--------|-------------|---------|
| `-r, --root-password` | MySQL root password | `rootpw` |
| `-d, --database` | Guacamole database name | `guacamoledb` |
| `-p, --password` | Guacamole user password | `guacamoleuserpw` |
| `-c, --config` | Load from configuration file | - |
| `-h, --help` | Show help message | - |

### Configuration File Format

Create a `.env` style file:
```bash
ROOT_PASSWORD=mySecureRootPassword123!
GUACAMOLE_DB=guacamole_production
GUACAMOLE_PASSWORD=mySecureUserPassword456!
```

## What the automation does

The `prepare.sh` script automatically:

1. Parses configuration parameters or loads from file
2. Generates `docker-compose.yml` from template with your credentials
3. Creates necessary directories (`scripts/`, `data/mysql/`)
4. Generates the MySQL initialization script (`initdb.sql`)
5. Starts all Docker services
6. Waits for MySQL to be ready and initialized
7. Provides status information

## Manual Operations

### Check status
```bash
docker-compose ps
```

### View logs
```bash
docker-compose logs -f
```

### Stop services
```bash
docker-compose down
```

### Clean reset (removes all data)
```bash
docker-compose down -v
rm -rf data/
```

## Directory Structure

```
.
├── docker-compose.yml.template  # Template for Docker services
├── docker-compose.yml          # Generated Docker services (do not edit)
├── prepare.sh                  # Automated setup script
├── cleanup.sh                  # Cleanup script
├── config.env.example          # Example configuration file
├── README.md                   # This documentation
├── scripts/                    # Database initialization scripts
│   └── initdb.sql             # Generated MySQL schema
└── data/                      # Persistent data (created during setup)
    └── mysql/                 # MySQL data directory
```

## Services

- **guacd**: Guacamole daemon (proxy)
- **guacamole-db**: MySQL database
- **guacamole**: Web application (port 8080)

## Configuration

Database credentials are configured via:
1. Command line arguments
2. Configuration file
3. Default values (if none provided)

Default values:
- Root password: `rootpw`
- Database: `guacamoledb`
- User: `guacamole_user`
- User password: `guacamoleuserpw`

## Troubleshooting

If the setup fails:

1. Check Docker is running: `docker ps`
2. View logs: `docker-compose logs`
3. Clean reset and try again:
   ```bash
   docker-compose down -v
   rm -rf data/ scripts/initdb.sql
   ./prepare.sh
   ```
