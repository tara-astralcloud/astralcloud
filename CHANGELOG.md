# Changelog

All notable changes to AstralCloud are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added

### Changed

### Fixed

## [0.2.0] - 2026-05-28

### Added

- `dashboard/`: Next.js 14 App Router dashboard with Keycloak OIDC via Auth.js v5
  - iCloud-style home screen with live clock widget, app grid, and user menu (sign out)
  - Route protection via `src/middleware.ts` — all routes require session except `/login`, `/api/auth`, `/api/health`
  - `/api/health` endpoint for Kubernetes liveness/readiness probes
  - 3-stage ARM64 Dockerfile (`linux/arm64`, `output: standalone`, `node:20-alpine`)
  - `.env.example` for local development setup
- `infra/helm/dashboard/`: Local Helm chart for dashboard deployment to k3s
  - `deployment.yaml`, `service.yaml`, `ingress.yaml` with resource limits and health probes
  - Secrets injected from `dashboard-secret` k8s Secret (never in values.yaml)
- `infra/terraform/modules/platform/`: Added `null_resource.dashboard` (4th platform component)
  - Creates `astralcloud` namespace and `dashboard-secret` from env vars
  - Deploys dashboard Helm chart; depends on Keycloak being up
- `infra/terraform/variables.tf`: Added `dashboard_client_secret` and `dashboard_auth_secret` (both sensitive)

### Added

- `infra/terraform/modules/platform/`: Terraform module that installs MetalLB, ingress-nginx, and Keycloak via Helm as `local-exec` provisioners — single `terraform apply` provisions cluster + all platform services
  - MetalLB 0.14.9 (L2 mode, IP pool `192.168.0.200–192.168.0.220`)
  - ingress-nginx 4.10.1 (LoadBalancer via MetalLB, default ingress class)
  - Keycloak 26.6.2 via `codecentric/keycloakx` 7.2.0 (uses `quay.io/keycloak/keycloak`, separate `postgres:16-alpine` StatefulSet, `keycloak.astralcloud.local`)
- `infra/helm/`: Helm values files for MetalLB, ingress-nginx, and Keycloak
  - `infra/helm/metallb/crds/ip-address-pool.yaml`: IPAddressPool + L2Advertisement CRDs
  - `infra/helm/keycloak/postgres.yaml`: standalone PostgreSQL StatefulSet + Service + PVC
- `infra/terraform/variables.tf`: added `keycloak_admin_password` (sensitive), `metallb_ip_range`, `platform_force_reprovision`
- `infra/terraform/outputs.tf`: added `ingress_nginx_ip` and `keycloak_url` outputs

### Changed

- `infra/terraform/modules/k3s-node/main.tf`: fixed `data.external` node token read to use `sudo -S` (password piped via stdin) — `sudo -n` was unreliable without a cached TTY session
- `CLAUDE.md`: updated Repository Structure, Infrastructure commands, and Lessons Learned (Bitnami Docker Hub removal, keycloakx duplicate env vars, null_resource rollout failure handling)

## [0.1.7] - 2026-05-28

### Changed

- `infra/terraform/`: switch SSH auth from private key to password, passed via `TF_VAR_ssh_password` env var (never stored in any committed file)
  - `modules/k3s-node/`: `ssh_private_key_path` removed; `ssh_password` added (sensitive)
  - Connection blocks updated to `password` auth
  - `data.external` node token read uses `sshpass -e` + `sudo cat` (token file is root-only)
  - New `null_resource.kubeconfig` runs `local-exec` to scp + patch kubeconfig automatically — no manual steps needed after `terraform apply`
  - `outputs.tf`: replaced manual `kubeconfig_command` output with `verify_cluster`
  - `terraform.tfvars.example`: removed `ssh_private_key_path`, added `TF_VAR_ssh_password` usage comment

## [0.1.6] - 2026-05-28

### Added

- `infra/terraform/`: Terraform module to provision k3s cluster on Raspberry Pi (ARM64)
  - Root module with server + multi-node agent support via `for_each`
  - `modules/k3s-node/`: reusable module for server and agent provisioning via SSH remote-exec
  - Input validation on `k3s_version`, `server_node_ip`, and `agent_node_ips`
  - Safe node token retrieval using `data.external` + python3 JSON encoding
  - Agent install uses `K3S_TOKEN_FILE` to avoid token exposure in `/proc`/`ps`
- `.gitignore`: Terraform entries (`.terraform/`, `*.tfvars`, `tfplan`, etc.)

## [0.1.5] - 2026-05-28

### Added

- `terraform` skill (`.claude/skills/terraform.md`): deep knowledge on Terraform with AstralCloud-specific patterns, security rules, ARM64/Pi considerations, and review checklist
- `k3s` skill (`.claude/skills/k3s.md`): deep knowledge on k3s, Helm, MetalLB, ingress-nginx, Longhorn, and day-2 operations

### Changed

- `dev-practice` skill: full rewrite enforcing TDD (Red→Green→Refactor), code quality standards (Go + Next.js), performance and scalability requirements, and pre-PR checklist
- CLAUDE.md: added Lessons Learned section recording past mistakes by area so they are never repeated
- Removed duplicate terraform and k3s command files — these are skills, not commands

## [0.1.4] - 2026-05-28

### Added

- Root README.md with platform overview, development setup, and release docs
- `.githooks/commit-msg` and `.githooks/pre-push` hooks committed to repo

### Changed

- CLAUDE.md: fix Helm path to `./infra/helm/platform`

## [0.1.3] - 2026-05-28

### Added

- code-review skill: review code with agent second opinion and user approval gate before commit

### Changed

- git-manage skill: invoke `/code-review` and require user approval before every commit

## [0.1.1] - 2026-05-28

### Added

- GitHub Actions workflows: release-tag on merge to main, release on tag push
- Claude Code skills: github-config, dev-practice

### Changed

- git-manage skill: enforce PR-only workflow, invoke version-manage before commit
- Prettier hook updated to use safe read pattern for file paths with spaces

## [0.1.0] - 2026-05-27

### Added

- Initial project setup with CLAUDE.md
- Claude Code skills: git-manage, create-doc, version-manage
- Project configuration (.claude settings, agents, rules)
