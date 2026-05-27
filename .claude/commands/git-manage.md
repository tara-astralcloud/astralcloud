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

### Quick Commit & Push

When asked to "commit and push" or "save changes":

1. Run `git status` to show what will be committed
2. Stage relevant files (`git add <files>` — never `git add .` blindly)
3. Commit with a conventional message
4. Push to the current branch (`git push` or `git push -u origin <branch>` for new branches)

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
