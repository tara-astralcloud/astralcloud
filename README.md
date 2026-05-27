# AstralCloud

Self-hosted home cloud platform designed to run on k3s/Kubernetes (Raspberry Pi nodes).

## Overview

AstralCloud is the platform core — it provides a Dashboard UI, core services, and all infrastructure code. Independent apps live in their own repos under the `tara-astralcloud` org, publish Docker images, and are installed or uninstalled from the Dashboard via Helm.

## Repository Structure

```
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

## Core Services

| Service         | Tech     | Notes                            |
| --------------- | -------- | -------------------------------- |
| Auth            | Keycloak | Shared SSO/OIDC for all services |
| Dashboard UI    | Next.js  | Central hub and app marketplace  |
| File Storage    | Go       | Owns its own database            |
| Media Streaming | Go       | Owns its own database            |

## Development

### Prerequisites

- Go 1.22+
- Node 20+
- Docker (with `linux/arm64` build support via QEMU)
- Helm 3+
- Terraform
- k3s or k8s cluster

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
go build ./...
go test ./... -race
go vet ./...
```

### Infrastructure (`infra/`)

```bash
terraform init
terraform plan
terraform apply

helm install astralcloud ./infra/helm/platform -n astralcloud
helm upgrade astralcloud ./infra/helm/platform -n astralcloud
```

## Git Setup

After cloning, configure the local git hooks:

```bash
git config core.hooksPath .githooks
chmod +x .githooks/commit-msg .githooks/pre-push
git config user.email "ananthupmadhu@gmail.com"
```

Hooks enforce Conventional Commits and block direct pushes to `main`.

## App Integration Contract

External apps must:

1. Be hosted under the `tara-astralcloud` GitHub org
2. Publish a Docker image built for `linux/arm64`
3. Ship a Helm chart with standard `values.yaml` (image, resources, ingress)
4. Use Keycloak OIDC for auth (client credentials provided at install time)

## Deployment

- **Target node:** Raspberry Pi (ARM64)
- **Cluster:** k3s (dev/home) or k8s (production)
- **Namespace:** `astralcloud` (platform), per-app namespaces for installed apps
- **Images:** published to `ghcr.io/tara-astralcloud/<service>` once services are built

## Release

Releases are automated via GitHub Actions:

1. Bump `VERSION` and update `CHANGELOG.md`
2. Merge to `main` — CI creates the git tag automatically
3. Tag push triggers a GitHub Release using the full contents of `CHANGELOG.md` as the release body

See [CHANGELOG.md](CHANGELOG.md) for release history.
