# Woodpecker CI Server

A Docker-based setup for [Woodpecker CI](https://woodpecker-ci.org/), a lightweight continuous integration server with GitHub integration.

## Prerequisites

- Docker and Docker Compose
- Node.js (optional, for npm scripts)
- GitHub OAuth Application

## Setup

1. Copy the environment example file:
   ```bash
   cp .env.example .env
   ```

2. Create a GitHub OAuth App at https://github.com/settings/developers:
   - Set **Homepage URL** to your Woodpecker host (e.g., `http://localhost:8000`)
   - Set **Authorization callback URL** to `{YOUR_HOST}/authorize`

3. Update `.env` with your values:
   - `WOODPECKER_HOST` - URL where Woodpecker will be accessible
   - `WOODPECKER_GITHUB_CLIENT` - GitHub OAuth Client ID
   - `WOODPECKER_GITHUB_SECRET` - GitHub OAuth Client Secret
   - `WOODPECKER_AGENT_SECRET` - Random secret for agent authentication (generate with `openssl rand -hex 32`)
   - `WOODPECKER_ADMIN` - Your GitHub username for admin access

## Usage

Start the server:
```bash
npm start
# or
docker compose up -d
```

Stop the server:
```bash
npm stop
```

View logs:
```bash
npm run logs          # All services
npm run logs:server   # Server only
npm run logs:agent    # Agent only
```

Check status:
```bash
npm run status
```

Update to latest images:
```bash
npm run update
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `WOODPECKER_HOST` | Public URL of the server | - |
| `WOODPECKER_GITHUB_CLIENT` | GitHub OAuth Client ID | - |
| `WOODPECKER_GITHUB_SECRET` | GitHub OAuth Client Secret | - |
| `WOODPECKER_AGENT_SECRET` | Secret for agent-server communication | - |
| `WOODPECKER_ADMIN` | GitHub username(s) with admin access | - |
| `WOODPECKER_OPEN` | Allow open registration | `true` |
| `WOODPECKER_MAX_WORKFLOWS` | Max concurrent workflows per agent | `1` |

## Architecture

- **woodpecker-server** - Web UI and API (port 8000)
- **woodpecker-agent** - Executes pipelines using Docker

## License

This setup configuration is provided as-is. Woodpecker CI is licensed under Apache 2.0.
