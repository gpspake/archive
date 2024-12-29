#!/bin/bash

# Run persistent Postgres DB on Droplet with SSL
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

# Check if the Docker volume for data exists; create it if not
if ! docker volume ls | grep -q archive-postgres-data; then
  echo "Creating Docker volume archive-postgres-data..."
  docker volume create archive-postgres-data
else
  echo "Docker volume archive-postgres-data already exists. Skipping creation."
fi

# Check if the Docker volume for SSL exists; create it if not
if ! docker volume ls | grep -q archive-postgres-ssl; then
  echo "Creating Docker volume archive-postgres-ssl..."
  docker volume create archive-postgres-ssl
fi

# Populate SSL volume if not already populated
docker run --rm \
  -v archive-postgres-ssl:/var/lib/postgresql/ssl \
  postgres:15 bash -c " \
    openssl req -new -x509 -days 365 -nodes -out /var/lib/postgresql/ssl/server.crt -keyout /var/lib/postgresql/ssl/server.key -subj '/CN=postgres' && \
    chmod 600 /var/lib/postgresql/ssl/server.key && \
    chown postgres:postgres /var/lib/postgresql/ssl/server.key /var/lib/postgresql/ssl/server.crt"

# Run the Postgres container with SSL enabled
docker run -d \
  --name postgres \
  --network archive-app-network \
  -v archive-postgres-data:/var/lib/postgresql/data \
  -v archive-postgres-ssl:/var/lib/postgresql/ssl \
  -e POSTGRES_USER="$POSTGRES_USER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -e POSTGRES_DB="$POSTGRES_DB" \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -p 5432:5432 \
  postgres:15 \
  -c ssl=on \
  -c ssl_cert_file=/var/lib/postgresql/ssl/server.crt \
  -c ssl_key_file=/var/lib/postgresql/ssl/server.key
