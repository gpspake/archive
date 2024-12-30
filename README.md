# Simple Web App

A web application built with Go, Echo, PostgreSQL, and HTMX. This app demonstrates basic routing, pagination, and full text search.

Demo: https://archive.georgespake.com

---

## Features

- **Releases Management**: View a paginated, searchable list of music releases with details like release year and associated artists.
- **Full Text Search**: Uses native PostgreSQL FTS features.
- **Templating**: Uses Go's `html/template` package for rendering HTML pages.
- **In-Memory Testing**: Comprehensive test coverage with an in-memory SQLite database.

---

## Tech Stack

- **Backend**: [Go](https://golang.org/)
- **Web Framework**: [Echo](https://echo.labstack.com/)
- **Database**: [PostgreSQL](https://www.postgresql.org/)
- **Migrations**: [golang-migrate](https://github.com/golang-migrate/migrate)
- **Styling**: [Tailwind](https://github.com/golang-migrate/migrate)
- **Partial UI Re-rendering**: [HTMX](https://github.com/golang-migrate/migrate)
- **Testing**: Built-in Go testing framework with [Testify](https://github.com/stretchr/testify)

---

## Prerequisites

- Go 1.20 or later
- PostgreSQL installed locally (for development)
- Docker (optional, for containerized deployment)

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/gpspake/archive
cd archive
```

### 2. Install Dependencies
```bash
go mod tidy
```

#### 3. Install Air (for auto reloading)
Make sure `$GOPATH/bin` is in your Path
```bash
go install github.com/air-verse/air@latest
```

#### 4. Run the app
```bash
make dev
```

_Check out the [makefile](/makefile) for other options._

### 3. Visit the site

Navigate to [localhost:8087](http://localhost:8087) in a web browser.

## Deployment
This app is configured to deploy to a Digital Ocean using github actions. 

_Note: This section provides a general overview, but it's not a comprehensive deployment guide._

1. On the Droplet: Create a user for deployment and grant the user access to docker.
    ```
   sudo adduser deploy
   sudo usermod -aG docker deploy
   ```
1. Switch to the user and add the public key to the user's authorized keys
    ```
   sudo su - deploy
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   touch ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   echo "<YOUR_PUBLIC_KEY_CONTENT>" >> ~/.ssh/authorized_keys
   ```
1. On Github: Go to your repository's Settings > Secrets and variables > Actions and add the following secrets:
    ```
   DIGITALOCEAN_IP: The IP address of your droplet.
    SSH_USERNAME: Your SSH username on the droplet.
    SSH_PRIVATE_KEY: Your private SSH key for authentication.
   ```
1. Run the action. The [deploy workflow](./.github/workflows/deploy.yml)  is configured to run on push to main.
1. Verify the container is running:
    ```
   docker ps
    CONTAINER ID   IMAGE                   COMMAND   CREATED         STATUS         PORTS                                                   NAMES
    19282e9c5697   archive:latest   "./app"   3 minutes ago   Up 3 minutes   8087/tcp, 0.0.0.0:8087->8087/tcp, [::]:8087->8087/tcp   archive
   ```
1. Serve the app. Example using Caddy:
    ```
   archive.georgespake.com {
        reverse_proxy 127.0.0.1:8087

        tls {
                dns cloudflare {env.CLOUDFLARE_TOKEN}
        }

        log {
                output file /var/log/caddy/access.log
                format json
        }
    }
   ```