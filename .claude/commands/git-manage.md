# Git Manage Skill

Manage git operations for the AstralCloud project: quick commits, branch management, and full PR workflow.

## Config

- **Org:** https://github.com/tara-astralcloud
- **Remote:** https://github.com/tara-astralcloud/astralcloud
- **Git email:** ananthupmadhu@gmail.com
- **Default branch:** main

## Branch Naming Conventions

| Type           | Pattern                     | Example                 |
| -------------- | --------------------------- | ----------------------- |
| Feature        | `feat/<short-description>`  | `feat/file-storage-api` |
| Bug fix        | `fix/<short-description>`   | `fix/auth-token-expiry` |
| Infrastructure | `infra/<short-description>` | `infra/helm-keycloak`   |
| Dashboard/UI   | `ui/<short-description>`    | `ui/app-marketplace`    |
| Documentation  | `docs/<short-description>`  | `docs/app-contract`     |
| Release        | `release/<version>`         | `release/v1.0.0`        |

## Commit Message Conventions

Follow Conventional Commits:

```
<type>(<scope>): <short summary>
```

Types: `feat`, `fix`, `infra`, `docs`, `refactor`, `test`, `chore`

Scopes: `dashboard`, `file-storage`, `media-streaming`, `auth`, `helm`, `terraform`, `ci`

Examples:

- `feat(file-storage): add upload endpoint`
- `fix(auth): handle token refresh race condition`
- `infra(helm): add keycloak chart`

## Operations

### Quick Commit & Push (always via PR)

**Never push directly to `main`.** All changes go through a PR.

When asked to "commit and push" or "save changes":

1. **Check current branch** — if on `main`, create a new branch first using the appropriate naming convention before doing anything else
2. **Invoke `/version-manage`** — ask if the changes warrant a version bump (patch/minor/major) and update `VERSION` and `CHANGELOG.md` accordingly
3. Run `git status` to show what will be committed
4. Stage relevant files (`git add <files>` — never `git add .` blindly)
5. Commit with a conventional message
6. Push the branch: `git push -u origin <branch>`
7. **Open a PR automatically** (see Full PR Workflow below) and return the PR URL to the user

### Branch Management

**Create a branch:**

```bash
git checkout -b <type>/<description>
git push -u origin <type>/<description>
```

**Switch branch:**

```bash
git checkout <branch>
```

**Delete a branch (after merge):**

```bash
git branch -d <branch>
git push origin --delete <branch>
```

**List branches:**

```bash
git branch -a
```

### Full PR Workflow

When asked to "open a PR" or "create a pull request":

1. Ensure the branch is pushed: `git push -u origin <branch>`
2. Create PR via `gh`:

```bash
gh pr create \
  --title "<type>(<scope>): <summary>" \
  --body "$(cat <<'EOF'
## Summary
- <bullet points of changes>

## Test plan
- [ ] <what to test>
EOF
)" \
  --base main
```

3. Return the PR URL to the user.

### Check Status

```bash
git status
git log --oneline -10
git diff --stat
```

## Important Rules

- Always confirm before force-pushing or deleting branches
- Never commit directly to `main`
- Always verify `git config user.email` is `ananthupmadhu@gmail.com` before pushing
- Build for `linux/arm64` when committing Dockerfiles or CI changes
