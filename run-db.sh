#!/bin/bash

# Run persistent Postgres DB on Droplet
# Requires the following environment variables to be set:
# POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# Check if required environment variables are set
if [[ -z "$POSTGRES_USER" || -z "$POSTGRES_PASSWORD" || -z "$POSTGRES_DB" ]]; then
  echo "Error: Required environment variables (POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB) are not set."
  echo "Please set them in the environment (e.g., via DigitalOcean console) and try again."
  exit 1
fi

# Check if the Docker network exists; create it if not
if ! docker network ls | grep -q archive-app-network; then
  echo "Creating Docker network archive-app-network..."
  docker network create archive-app-network
else
  echo "Docker network archive-app-network already exists. Skipping creation."
fi

# Check if the Docker volume exists; create it if not
if ! docker volume ls | grep -q archive-postgres-data; then
  echo "Creating Docker volume archive-postgres-data..."
  docker volume create archive-postgres-data
else
  echo "Docker volume archive-postgres-data already exists. Skipping creation."
fi

# Run the Postgres container with the named volume
docker run -d \
  --name postgres \
  --network archive-app-network \
  -v archive-postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_USER="$POSTGRES_USER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -e POSTGRES_DB="$POSTGRES_DB" \
  -p 5432:5432 \
  postgres:15
