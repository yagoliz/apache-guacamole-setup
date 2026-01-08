#!/usr/bin/bash

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --root-password PASSWORD     MySQL root password (default: rootpwguacamolesuckit!)"
    echo "  -d, --database DATABASE          Guacamole database name (default: guacamoledb)"
    echo "  -p, --password PASSWORD          Guacamole user password (default: guacamoleuserpw)"
    echo "  -c, --config FILE                Load configuration from file"
    echo "  -h, --help                       Show this help message"
    echo ""
    echo "Configuration file format (.env style):"
    echo "  ROOT_PASSWORD=rootpw"
    echo "  GUACAMOLE_DB=guacamoledb"
    echo "  GUACAMOLE_PASSWORD=guacamoleuserpw"
    echo ""
    echo "Example:"
    echo "  $0 -r 'myRootPass123!' -d 'myguacdb' -p 'myUserPass456!'"
    echo "  $0 -c config.env"
}

# Default values
ROOT_PASSWORD="rootpw"
GUACAMOLE_DB="guacamoledb"
GUACAMOLE_PASSWORD="guacamoleuserpw"

# Function to load config file
load_config() {
    local config_file="$1"
    if [ ! -f "$config_file" ]; then
        echo "❌ Configuration file not found: $config_file"
        exit 1
    fi
    
    echo "📄 Loading configuration from: $config_file"
    # Source the config file, but only extract our expected variables
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # Remove quotes from value
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        
        case $key in
            ROOT_PASSWORD) ROOT_PASSWORD="$value" ;;
            GUACAMOLE_DB) GUACAMOLE_DB="$value" ;;
            GUACAMOLE_PASSWORD) GUACAMOLE_PASSWORD="$value" ;;
        esac
    done < "$config_file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--root-password)
            ROOT_PASSWORD="$2"
            shift 2
            ;;
        -d|--database)
            GUACAMOLE_DB="$2"
            shift 2
            ;;
        -p|--password)
            GUACAMOLE_PASSWORD="$2"
            shift 2
            ;;
        -c|--config)
            load_config "$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo "🚀 Starting Guacamole setup automation..."
echo "📋 Configuration:"
echo "   Root Password: ${ROOT_PASSWORD:0:3}***"
echo "   Database: $GUACAMOLE_DB"
echo "   User Password: ${GUACAMOLE_PASSWORD:0:3}***"
echo ""

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p scripts data/mysql

# Check for SELinux and provide info
if command -v getenforce >/dev/null 2>&1; then
    if [ "$(getenforce)" = "Enforcing" ]; then
        echo "ℹ️  SELinux is enabled - volume mounts configured with proper labels"
    fi
fi

# Generate docker-compose.yml from template
echo "🔧 Generating docker-compose.yml from template..."
if [ ! -f "docker-compose.yml.template" ]; then
    echo "❌ docker-compose.yml.template not found!"
    exit 1
fi

# Use sed to replace placeholders (escaping special characters)
sed -e "s|<ROOT_PASSWORD>|${ROOT_PASSWORD}|g" \
    -e "s|<GUACAMOLE_DB>|${GUACAMOLE_DB}|g" \
    -e "s|<GUACAMOLE_PASSWORD>|${GUACAMOLE_PASSWORD}|g" \
    docker-compose.yml.template > docker-compose.yml

echo "✅ docker-compose.yml generated successfully"

# Get db configuration
echo "📋 Generating database initialization script..."
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > scripts/initdb.sql

if [ ! -s scripts/initdb.sql ]; then
    echo "❌ Failed to generate initdb.sql"
    exit 1
fi

echo "✅ Database initialization script created successfully"

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose down -v 2>/dev/null || true

# Start the services
echo "🐳 Starting Guacamole services..."
docker-compose up -d

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to initialize..."
max_attempts=60
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker-compose exec -T guacamole-db mysql -u root -p"${ROOT_PASSWORD}" -e "SELECT 1" "${GUACAMOLE_DB}" >/dev/null 2>&1; then
        echo "✅ MySQL is ready!"
        break
    fi
    
    attempt=$((attempt + 1))
    echo "⏳ Waiting for MySQL... (attempt $attempt/$max_attempts)"
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ MySQL failed to start within expected time"
    echo "📋 Checking logs:"
    docker-compose logs guacamole-db
    exit 1
fi

# Wait a bit more to ensure the database is fully initialized
sleep 10

# Check if database is already initialized and execute initialization script if needed
echo "🔍 Checking database initialization status..."
if docker-compose exec -T guacamole-db mysql -u root -p"${ROOT_PASSWORD}" "${GUACAMOLE_DB}" -e "SHOW TABLES LIKE 'guacamole_user';" | grep -q "guacamole_user"; then
    echo "✅ Database already initialized, skipping initialization script"
else
    echo "🗄️  Executing database initialization script..."
    if docker-compose exec -T guacamole-db mysql -u root -p"${ROOT_PASSWORD}" "${GUACAMOLE_DB}" < scripts/initdb.sql; then
        echo "✅ Database initialization completed successfully"
    else
        echo "❌ Database initialization failed"
        echo "📋 Checking database logs:"
        docker-compose logs guacamole-db
        exit 1
    fi
fi

echo "🎉 Guacamole setup completed successfully!"
echo "🌐 Guacamole is available at: http://localhost:8080/guacamole"
echo "👤 Default credentials: guacadmin / guacadmin"
echo ""
echo "📊 To check status: docker-compose ps"
echo "📋 To view logs: docker-compose logs -f"
echo "🛑 To stop: docker-compose down" 
