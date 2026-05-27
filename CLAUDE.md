# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AstralCloud** (GitHub org: `tara-astralcloud`) is a self-hosted home cloud platform designed to run on k3s/k8s (initially Raspberry Pi nodes). This repo is the **platform core** — it contains the Dashboard UI, core services, and all infrastructure code. Independent apps live in their own repos under the `tara-astralcloud` org, publish Docker images, and are installed/uninstalled from the Dashboard via Helm.

## Repository Structure

```text
tara-astralcloud/
├── dashboard/           # Next.js frontend (platform hub + app marketplace UI)
├── services/
│   ├── file-storage/    # Go service
│   └── media-streaming/ # Go service
├── infra/
│   ├── terraform/       # Cluster provisioning
│   └── helm/            # Helm charts for core platform services
└── docs/
```

## Architecture

### Platform vs Apps

- **This repo** = platform core: Dashboard UI, Keycloak auth, File Storage, Media Streaming, Terraform, Helm charts
- **App repos** = independently developed apps under `tara-astralcloud` org that ship their own Helm chart + Docker image. The Dashboard calls the k8s/Helm API to install or uninstall them per user request.

### Core Services

| Service         | Tech     | Notes                                                    |
| --------------- | -------- | -------------------------------------------------------- |
| Auth            | Keycloak | Deployed as Helm chart, shared SSO/OIDC for all services |
| Dashboard UI    | Next.js  | Central hub and app marketplace                          |
| File Storage    | Go       | Owns its own database                                    |
| Media Streaming | Go       | Owns its own database                                    |

### Key Design Decisions

- **Polyglot:** Each service uses the language best suited to it. Go for resource-constrained backend services (low memory, fast startup on Pi). Next.js for the dashboard.
- **Database per service:** No shared databases. Each service chooses its own (PostgreSQL, SQLite, Redis, etc.) based on its needs.
- **Helm-based app lifecycle:** Apps are Helm charts. Install/uninstall from Dashboard triggers `helm install` / `helm uninstall` against the k3s/k8s cluster.
- **k3s/k8s agnostic:** Infra and Helm charts must work on both k3s (Pi) and standard k8s.

### Auth Flow

All services and apps delegate authentication to Keycloak via OIDC. The Dashboard handles the OAuth2 login flow. Service-to-service calls use Keycloak-issued JWTs.

## Development Commands

Commands will be added here as each service is built out.

### Dashboard UI (`dashboard/`)

```bash
npm install
npm run dev        # Start dev server
npm run build      # Production build
npm run lint       # Lint
npm test           # Run tests
```

### Go Services (`services/*`)

```bash
go build ./...                   # Build
go test ./...                    # All tests
go test ./... -run TestName      # Single test
go vet ./...                     # Lint
```

### Infrastructure (`infra/`)

```bash
terraform init
terraform plan
terraform apply

helm install astralcloud ./helm/platform -n astralcloud
helm upgrade astralcloud ./helm/platform -n astralcloud
```

## App Integration Contract

External apps that want to integrate with AstralCloud must:

1. Be hosted under the `tara-astralcloud` GitHub org
2. Publish a Docker image to a container registry (built for `linux/arm64`)
3. Ship a Helm chart with standard `values.yaml` (image, resources, ingress)
4. Use Keycloak OIDC for auth (client credentials provided at install time by the platform)

## Git & GitHub

- **Org:** [https://github.com/tara-astralcloud](https://github.com/tara-astralcloud)
- **Git email:** `ananthupmadhu@gmail.com`

Ensure your local git config uses the correct email before pushing:

```bash
git config user.email "ananthupmadhu@gmail.com"
```

## Deployment Target

- **Node:** Raspberry Pi (ARM64) — Docker images must be built for `linux/arm64`
- **Cluster:** k3s (dev/home) or k8s (production)
- **Namespace:** `astralcloud` (platform), per-app namespaces for installed apps
