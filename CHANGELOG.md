# Changelog

All notable changes to AstralCloud are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added

### Changed

### Fixed

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
