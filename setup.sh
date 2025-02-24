#!/bin/bash

# Step 1: Restore PostgreSQL Schema
echo "Starting PostgreSQL schema restoration..."

# Prompt for PostgreSQL username
read -p "Enter PostgreSQL Username: " DB_USER

# Prompt for PostgreSQL password (hidden input)
read -s -p "Enter PostgreSQL Password: " DB_PASS
echo ""

# Set database name (change if needed)
DB_NAME="md_db"

# Export password temporarily to avoid prompt
export PGPASSWORD=$DB_PASS

# Check if database exists
DB_EXISTS=$(psql -U $DB_USER -h localhost -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" != "1" ]; then
    echo "Database '$DB_NAME' does not exist. Creating it..."
    psql -U $DB_USER -h localhost -c "CREATE DATABASE $DB_NAME;"
    
    if [ $? -eq 0 ]; then
        echo "✅ Database '$DB_NAME' created successfully!"
    else
        echo "❌ Failed to create database!"
        unset PGPASSWORD
        exit 1
    fi
else
    echo "✅ Database '$DB_NAME' already exists."
fi

# Restore schema from file
echo "Restoring schema..."
psql -U $DB_USER -h localhost -d $DB_NAME -f schema_backup.sql

if [ $? -eq 0 ]; then
    echo "✅ Schema restored successfully!"
else
    echo "❌ Schema restoration failed!"
    unset PGPASSWORD
    exit 1
fi

# Unset password for security
unset PGPASSWORD

# Step 2: Start Kafka with Docker Compose
echo "Checking if Kafka is already running..."

if docker ps | grep -q "kafka"; then
    echo "✅ Kafka is already running."
else
    echo "Starting Kafka..."
    docker-compose up -d

    if [ $? -eq 0 ]; then
        echo "✅ Kafka started successfully!"
    else
        echo "❌ Failed to start Kafka!"
        exit 1
    fi
fi



# Step 3: Clone repositories at the parent directory level
echo "Cloning repositories..."

# Navigate to the parent directory of `md-setup`
cd "$(dirname "$0")/.." || { echo "❌ Failed to navigate to parent directory!"; exit 1; }

# Clone repositories
git clone https://github.com/mrkk7999/md-api-gateway.git
git clone https://github.com/mrkk7999/md-auth-svc.git
git clone https://github.com/mrkk7999/md-tnt-mgmt.git
git clone https://github.com/mrkk7999/md-geo-track.git
git clone https://github.com/mrkk7999/md-geo-stream.git

if [ $? -eq 0 ]; then
    echo "✅ Repositories cloned successfully!"
else
    echo "❌ Failed to clone repositories!"
    exit 1
fi

# Step 4: Pull and Start Redis on Port 6379
echo "Pulling Redis Docker image..."
docker pull redis

if [ $? -eq 0 ]; then
    echo "✅ Redis image pulled successfully!"
else
    echo "❌ Failed to pull Redis image!"
    exit 1
fi

echo "Starting Redis container..."
docker run -d --name redis-server -p 6379:6379 redis

if [ $? -eq 0 ]; then
    echo "✅ Redis started successfully on port 6379!"
else
    echo "❌ Failed to start Redis!"
    exit 1
fi

echo "✅ Setup completed!"