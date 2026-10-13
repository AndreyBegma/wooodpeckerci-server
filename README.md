# Woodpecker CI Server

**A self-hosted [Woodpecker CI](https://woodpecker-ci.org/) v3 for GitHub repositories, in a few Docker Compose files.**

Woodpecker is a small CI server, but running it for real means more than one
`docker run`: a GitHub OAuth app, a shared secret between server and agents,
agents on a different machine from the server, memory limits so one test step
cannot take the host down, and a build image that does not install toolchains
on every step. This repository holds that setup as plain configuration — one
compose file per topology, `.env` examples, and a CI image with Node and Bun.

**Who it is for:** a developer or a small team that wants its own CI for GitHub
repositories on hardware it already has — a laptop, a NAS, a spare server —
with builds running as Docker containers.

## What is in the repository

| File | What it runs |
|---|---|
| [`docker-compose.yml`](docker-compose.yml) | Server and agent on one host. Compose profiles `all`, `server` and `agent` start them together or apart. |
| [`docker-compose.nas.yml`](docker-compose.nas.yml) | Server only, closed registration, 384 MB memory cap. The web UI is not published to the LAN — it is reached through a Cloudflare Tunnel on an external Docker network; gRPC port 9000 is published for remote agents. |
| [`docker-compose.agent.yml`](docker-compose.agent.yml) | One agent on its own, pointed at a remote server over gRPC. |
| [`docker-compose.agents.devbox.yml`](docker-compose.agents.devbox.yml) | Five agents on one build host, one workflow each, with an 8 GiB memory limit (no swap) on every step container. |
| [`Dockerfile.ci`](Dockerfile.ci) | The CI image for pipeline steps: `node:24-bookworm-slim` plus Bun, so check steps install nothing at run time. |
| [`.env.example`](.env.example), [`.env.nas.example`](.env.nas.example), [`.env.agent.example`](.env.agent.example) | Environment for the single-host, NAS-server and remote-agent setups. |
| [`package.json`](package.json) | npm scripts wrapping `docker compose` for the single-host setup. |
| [`deploy.sh`](deploy.sh), [`deploy.filter`](deploy.filter) | rsync of the single-host setup to a remote server. |

All setups use the official `woodpeckerci/woodpecker-server:v3` and
`woodpeckerci/woodpecker-agent:v3` images. Agents run pipelines through the
host's Docker socket.

## Quick start (single host)

Requirements: Docker with Docker Compose, a GitHub account. Node.js is optional
— it only runs the npm scripts below.

1. Copy the environment file:

   ```sh
   cp .env.example .env
   ```

2. Create a GitHub OAuth app at <https://github.com/settings/developers>:
   - **Homepage URL** — your Woodpecker host, e.g. `http://localhost:8000`
   - **Authorization callback URL** — `{WOODPECKER_HOST}/authorize`

3. Fill in `.env`: `WOODPECKER_HOST`, `WOODPECKER_GITHUB_CLIENT`,
   `WOODPECKER_GITHUB_SECRET`, `WOODPECKER_ADMIN`, `WOODPECKER_REPO_OWNERS`, and
   a `WOODPECKER_AGENT_SECRET` generated with `openssl rand -hex 32`.

4. Start the server and the agent:

   ```sh
   npm start
   # or, without Node.js:
   docker compose --profile all up -d
   ```

Open `WOODPECKER_HOST` (port 8000 by default), sign in with GitHub and enable a
repository.

## Commands

| Command | What it does |
|---|---|
| `npm start` | server and agent (`--profile all`) |
| `npm run start:server` / `npm run start:agent` | only the server, or only the agent |
| `npm stop` | stop everything (`stop:server`, `stop:agent` stop one side) |
| `npm run restart` | restart everything |
| `npm run logs` | follow all logs (`logs:server`, `logs:agent` for one service) |
| `npm run status` | container status |
| `npm run pull` | pull the latest v3 images |
| `npm run update` | pull and recreate |

The scripts drive `docker-compose.yml` only. The other compose files are
started directly, for example
`docker compose -f docker-compose.agent.yml --env-file .env.agent up -d`.

## Configuration

Variables read by [`docker-compose.yml`](docker-compose.yml):

| Variable | Description | Default |
|---|---|---|
| `WOODPECKER_HOST` | Public URL of the server | — |
| `WOODPECKER_GITHUB_CLIENT` | GitHub OAuth client ID | — |
| `WOODPECKER_GITHUB_SECRET` | GitHub OAuth client secret | — |
| `WOODPECKER_AGENT_SECRET` | Shared secret between server and agents | — |
| `WOODPECKER_ADMIN` | GitHub user(s) with admin access | — |
| `WOODPECKER_REPO_OWNERS` | GitHub owners whose repositories may be enabled (comma-separated) | — |
| `WOODPECKER_OPEN` | Allow open registration | `true` |
| `WOODPECKER_MAX_WORKFLOWS` | Concurrent workflows per agent | `1` |
| `WOODPECKER_GRPC_ADDR` | Server gRPC address the agent connects to | `woodpecker-server:9000` |

Privileged plugins are fixed in the compose file to
`woodpeckerci/plugin-docker-buildx` and `docker`, so image builds work out of
the box.

Set `WOODPECKER_OPEN=false` for any server reachable from the internet; with
open registration any GitHub user can sign in.

Woodpecker 3 renamed the shared secret to `WOODPECKER_GRPC_SECRET`. The NAS,
remote-agent and devbox compose files set both names from the same value so
server and agents always agree.

## Split topologies

The single-host file cannot run an agent without its server (`depends_on`), so
remote agents have their own files.

- **Server on a small box, agents elsewhere.** `docker-compose.nas.yml` runs the
  server alone and exposes gRPC on port 9000; agents on a stronger machine
  connect with `docker-compose.agent.yml` (one agent) or
  `docker-compose.agents.devbox.yml` (five agents). Images are built on the
  agent host, so a low-memory server never runs a build.
- **Several agents on one host.** The devbox file runs five agents with one
  workflow each — up to five pipelines at once — and caps every step container
  at 8 GiB of memory with swap equal to memory. The comments in the file record
  the sizing reasoning.

The NAS and agent files carry values specific to the owner's setup (host name,
LAN address, external network `luna_luna`); change them for yours.

## CI image

[`Dockerfile.ci`](Dockerfile.ci) builds a pipeline image with Node 24 and Bun.
Node is the base because Jest does not run under Bun's runtime; Bun is there
for dependency installs and Turborepo.

```sh
docker build -f Dockerfile.ci -t ci-node-bun .
```

Build it on the agent host and reference it by tag in pipeline steps; no
registry is needed when the agent uses the same Docker daemon.

## Deploying to a remote host

`deploy.sh` rsyncs `docker-compose.yml` and `package.json` (see
[`deploy.filter`](deploy.filter)) to `/var/app/apps/woodpecker` on a remote
host. Set `SERVER` at the top of the script first — it is empty in the
repository.

## License

This repository has no license file. Woodpecker CI itself is licensed under
Apache 2.0.
