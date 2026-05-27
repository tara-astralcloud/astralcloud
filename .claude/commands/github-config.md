# GitHub & Git Config Skill

Manage GitHub Actions workflows, repository configuration, branch protection, secrets, and git hooks for AstralCloud.

## Project Context

- **Org:** tara-astralcloud
- **Repo:** astralcloud
- **Target platform:** Raspberry Pi (linux/arm64)
- **Cluster:** k3s / k8s
- **Services:** Next.js dashboard, Go services (file-storage, media-streaming), Keycloak, Helm charts

---

## GitHub Actions Workflows

Workflows live in `.github/workflows/`. When creating a workflow, check if one already exists for that purpose before creating a new one.

### Workflow Templates

#### CI — Go Service

**File:** `.github/workflows/ci-<service>.yml`

```yaml
name: CI - <Service>

on:
  pull_request:
    paths:
      - "services/<service>/**"
  push:
    branches: [main]
    paths:
      - "services/<service>/**"

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"
          cache-dependency-path: services/<service>/go.sum
      - name: Lint
        run: go vet ./...
        working-directory: services/<service>
      - name: Test
        run: go test ./... -race -coverprofile=coverage.out
        working-directory: services/<service>
```

#### CI — Dashboard (Next.js)

**File:** `.github/workflows/ci-dashboard.yml`

```yaml
name: CI - Dashboard

on:
  pull_request:
    paths:
      - "dashboard/**"
  push:
    branches: [main]
    paths:
      - "dashboard/**"

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
          cache-dependency-path: dashboard/package-lock.json
      - run: npm ci
        working-directory: dashboard
      - run: npm run lint
        working-directory: dashboard
      - run: npm run build
        working-directory: dashboard
      - run: npm test -- --passWithNoTests
        working-directory: dashboard
```

#### Docker Build & Push (ARM64)

**File:** `.github/workflows/docker-<service>.yml`

```yaml
name: Docker - <Service>

on:
  push:
    tags: ["v*"]
    paths:
      - "services/<service>/**"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-qemu-action@v3
        with:
          platforms: arm64
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: services/<service>
          platforms: linux/arm64
          push: true
          tags: |
            ghcr.io/tara-astralcloud/<service>:${{ github.ref_name }}
            ghcr.io/tara-astralcloud/<service>:latest
```

#### Helm Lint & Validate

**File:** `.github/workflows/helm-lint.yml`

```yaml
name: Helm Lint

on:
  pull_request:
    paths:
      - "infra/helm/**"

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/setup-helm@v4
      - name: Lint charts
        run: helm lint ./infra/helm/platform
      - name: Template render check
        run: helm template astralcloud ./infra/helm/platform --debug > /dev/null
```

#### Release

**File:** `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags: ["v*"]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          body_path: CHANGELOG.md
          generate_release_notes: false
```

---

## Branch Protection Rules

When asked to set up branch protection for `main`:

```bash
gh api repos/tara-astralcloud/astralcloud/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null
```

Key rules to enforce:

- Require PR before merging
- Require status checks to pass (CI)
- No direct pushes to `main`
- Dismiss stale reviews on new commits

---

## GitHub Secrets & Environments

### List secrets

```bash
gh secret list
```

### Set a secret

```bash
gh secret set <SECRET_NAME> --body "<value>"
# or from env var
gh secret set <SECRET_NAME> --env-file .env
```

### Common secrets for AstralCloud

| Secret                    | Purpose                            |
| ------------------------- | ---------------------------------- |
| `GHCR_TOKEN`              | GitHub Container Registry push     |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin (staging/prod env)  |
| `KUBECONFIG`              | k3s cluster access for deploy jobs |

### Environments

Create `staging` and `production` environments with protection rules:

```bash
gh api repos/tara-astralcloud/astralcloud/environments/production \
  --method PUT \
  --field wait_timer=0 \
  --field reviewers='[]'
```

---

## Git Hooks (local)

Hooks live in `.githooks/`. Set them up with:

```bash
git config core.hooksPath .githooks
```

### commit-msg hook — enforce Conventional Commits

**File:** `.githooks/commit-msg`

```bash
#!/bin/sh
commit_msg=$(cat "$1")
pattern="^(feat|fix|infra|docs|refactor|test|chore)(\(.+\))?: .{1,72}"
if ! echo "$commit_msg" | grep -qE "$pattern"; then
  echo "ERROR: Commit message must follow Conventional Commits:"
  echo "  <type>(<scope>): <summary>"
  echo "  Types: feat, fix, infra, docs, refactor, test, chore"
  exit 1
fi
```

### pre-push hook — block direct push to main

**File:** `.githooks/pre-push`

```bash
#!/bin/sh
branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" = "main" ]; then
  echo "ERROR: Direct push to main is not allowed. Open a PR instead."
  exit 1
fi
```

After creating hooks, make them executable:

```bash
chmod +x .githooks/commit-msg .githooks/pre-push
```

Add to CLAUDE.md and README: developers must run `git config core.hooksPath .githooks` after cloning.

---

## Git Configuration

### Useful aliases (add to `.gitconfig` or suggest to user)

```bash
git config alias.lg "log --oneline --graph --decorate --all"
git config alias.st "status -sb"
git config alias.undo "reset --soft HEAD~1"
```

### Repo-level config

```bash
# Ensure correct email for this repo
git config user.email "ananthupmadhu@gmail.com"

# Use .githooks directory
git config core.hooksPath .githooks

# Always rebase on pull to keep history clean
git config pull.rebase true
```

---

## Important Rules

- Always use `linux/arm64` platform in Docker build workflows
- Use `ghcr.io/tara-astralcloud/<service>` as the image registry (GitHub Container Registry)
- Workflow files must use pinned action versions (e.g. `actions/checkout@v4`)
- Never store secrets in workflow files — use GitHub Secrets
- After creating a workflow, commit it on a branch and open a PR via `/git-manage`
