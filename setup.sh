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
echo "Starting Kafka..."
docker-compose up -d

if [ $? -eq 0 ]; then
    echo "✅ Kafka started successfully!"
else
    echo "❌ Failed to start Kafka!"
    exit 1
fi
