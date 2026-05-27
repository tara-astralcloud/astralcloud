# Changelog

All notable changes to AstralCloud are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added

### Changed

### Fixed

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
