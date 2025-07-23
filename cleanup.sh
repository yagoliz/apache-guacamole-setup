#!/usr/bin/bash

echo "🧹 Cleaning up Guacamole installation..."

# Stop and remove containers
echo "🛑 Stopping containers..."
docker-compose down -v 2>/dev/null || true

# Remove data directories and generated files
echo "🗑️  Removing data directories and generated files..."
rm -rf data/
rm -f scripts/initdb.sql
rm -f docker-compose.yml

echo "✅ Cleanup completed!"
echo "ℹ️  Generated docker-compose.yml removed"
echo "ℹ️  Run ./prepare.sh to set up again"
