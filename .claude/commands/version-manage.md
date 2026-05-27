# Version Manage Skill

Manage semantic versioning, changelogs, and releases for AstralCloud platform.

## Versioning Strategy

AstralCloud uses a **single platform-wide version** across all services in this repo.

Version file: `VERSION` at the repo root (plain text, e.g. `1.2.3`)

### Semantic Versioning Rules

| Bump    | When                                                                           |
| ------- | ------------------------------------------------------------------------------ |
| `MAJOR` | Breaking changes to the App Integration Contract, Helm chart API, or auth flow |
| `MINOR` | New features, new services, backward-compatible changes                        |
| `PATCH` | Bug fixes, security patches, config/infra tweaks                               |

---

## Operations

### 1. Show Current Version

```bash
cat VERSION
git tag --sort=-v:refname | head -5
```

### 2. Bump Version

When asked to bump the version:

1. Read the current version from `VERSION`
2. Ask which bump type if not specified: `major`, `minor`, or `patch`
3. Calculate the new version
4. Update `VERSION` file with the new version
5. Update the `## [Unreleased]` section header in `CHANGELOG.md` to `## [<new-version>] - <YYYY-MM-DD>`
6. Add a new empty `## [Unreleased]` section at the top
7. Commit: `chore(release): bump version to v<new-version>`

```bash
# Example
echo "1.3.0" > VERSION
```

### 3. Update Changelog

`CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com) format.

**When adding entries** (during development, not at release):

Add entries under `## [Unreleased]` grouped by:

```markdown
## [Unreleased]

### Added

- New feature description

### Changed

- What changed and why

### Fixed

- Bug that was fixed

### Removed

- What was removed
```

**Auto-populate from commits** by reading `git log` since the last tag:

```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Map commit types to changelog sections:

- `feat` → Added
- `fix` → Fixed
- `refactor` / `chore` → Changed
- breaking changes → note under Changed with **BREAKING:**

### 4. Create a Release

Full release workflow — run steps in order:

1. **Check working tree is clean:**

   ```bash
   git status
   ```

2. **Ensure on main branch:**

   ```bash
   git branch --show-current
   ```

3. **Bump version** (follow bump version steps above)

4. **Update CHANGELOG.md** — populate Unreleased section from commits if not already done

5. **Commit the release:**

   ```bash
   git add VERSION CHANGELOG.md
   git commit -m "chore(release): v<version>"
   ```

6. **Tag the release:**

   ```bash
   git tag -a v<version> -m "Release v<version>"
   ```

7. **Push with tags:**

   ```bash
   git push && git push --tags
   ```

8. **Create GitHub release:**

   ```bash
   gh release create v<version> \
     --title "v<version>" \
     --notes "$(sed -n '/^## \[<version>\]/,/^## \[/p' CHANGELOG.md | head -n -1)"
   ```

9. Return the GitHub release URL to the user.

---

## CHANGELOG.md Structure

Maintain this structure in `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to AstralCloud are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added

### Changed

### Fixed

## [1.0.0] - 2026-05-27

### Added

- Initial platform release
- Keycloak auth, Dashboard UI, File Storage, Media Streaming
- Helm charts for k3s/k8s deployment
```

---

## Important Rules

- Always release from `main` branch only
- Never skip tagging — Helm chart image tags and Dockerfiles reference the version tag
- Confirm with user before pushing tags (tags are hard to undo)
- Docker images must be tagged `v<version>` and built for `linux/arm64`
- After a release, remind the user to build and push Docker images for affected services
