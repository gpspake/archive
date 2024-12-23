# Stage 1: Build Tailwind CSS
FROM node:16 AS tailwind-build

WORKDIR /app

# Copy package.json and install npm dependencies
COPY package*.json ./
RUN npm install

# Copy the Tailwind config and source CSS file
COPY tailwind.config.js ./
COPY input.css ./
#COPY static ./static
COPY internal/templates ./internal/templates

# Build the Tailwind CSS file
RUN npm run tailwind

# Output the generated CSS file to a known location
RUN mkdir -p /output/static/css && cp -rf ./static/css /output/static/

# Inject CSS file hash into the HTML template to prevent caching across changes
RUN HASH=$(sha256sum /output/static/css/styles.css | awk '{print $1}') && \
    sed -i "s|{HASH_PLACEHOLDER}|${HASH}|" ./internal/templates/base.html && \
    cp -rf ./internal/templates /output/templates

RUN ls -la /output/static


# Stage 2: Build Go application
FROM golang:1.23 AS go-build

WORKDIR /app

# Copy Go module files and install dependencies
COPY go.mod go.sum ./
RUN go mod tidy

# Copy the Go source code
COPY . .

# Build the Go binary (statically linked for deployment)
RUN CGO_ENABLED=1 GOOS=linux go build -o /output/app ./cmd/main.go

# Stage 3: Final runtime container
FROM debian:bookworm-slim

WORKDIR /app

# Install PostgreSQL client for managing the database
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

# Copy the generated Tailwind CSS, modified themplates, and Go binary from the previous stages
COPY --from=tailwind-build /output/static ./static
COPY --from=tailwind-build /output/templates ./templates
COPY --from=go-build /output/app ./app
COPY migrations ./migrations

# Set environment variable for templates directory
ENV TEMPLATE_DIR=/app/templates

# Expose the port that the Go app will listen on (default 8087)
EXPOSE 8087

# Set the working directory back to /app to ensure migrations are found
WORKDIR /app

# Run the Go binary when the container starts
CMD ["./app"]