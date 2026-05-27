# Development Practice Skill

Enforce the AstralCloud development workflow: always start from a clean, up-to-date main branch before making any changes.

## Golden Rule

**Never make changes directly on `main`.** Every change — no matter how small — follows this workflow:

```
checkout main → pull latest → create branch → make changes → /git-manage
```

---

## Step-by-Step Workflow

### Before Making ANY Change

Run these steps first, every time:

**1. Switch to main**

```bash
git checkout main
```

**2. Pull latest code**

```bash
git pull origin main
```

If there are conflicts or uncommitted changes, resolve them before continuing:

```bash
# Stash uncommitted changes if needed
git stash
git pull origin main
git stash pop
```

**3. Create a new branch** using naming conventions from `/git-manage`:

| Type           | Pattern                     |
| -------------- | --------------------------- |
| Feature        | `feat/<short-description>`  |
| Bug fix        | `fix/<short-description>`   |
| Infrastructure | `infra/<short-description>` |
| Dashboard/UI   | `ui/<short-description>`    |
| Documentation  | `docs/<short-description>`  |
| Release        | `release/<version>`         |

```bash
git checkout -b <type>/<description>
```

**4. Verify you are on the new branch before touching any files:**

```bash
git branch --show-current
```

Only proceed if this shows your new branch — never `main`.

---

### Making Changes

- Make all code changes on the new branch
- Commit incrementally as work progresses — don't batch everything into one giant commit
- Each commit should be atomic: one logical change per commit

---

### Pushing & Version Management

When changes are ready to push, invoke `/git-manage` which will:

1. Check the branch (never `main`)
2. Invoke `/version-manage` — determine if a version bump is needed (patch/minor/major), update `VERSION` and `CHANGELOG.md`
3. Stage and commit with a Conventional Commits message
4. Push the branch
5. Open a PR against `main` and return the PR URL

---

## Full Example

```bash
# 1. Start clean
git checkout main
git pull origin main

# 2. Create branch
git checkout -b feat/file-storage-upload

# 3. Make changes...

# 4. When ready — invoke /git-manage
# /git-manage will handle version bump, commit, push, and PR
```

---

## Checklist (run through this before every PR)

- [ ] Started from `main` with latest code pulled
- [ ] All changes are on a named branch (not `main`)
- [ ] `VERSION` and `CHANGELOG.md` updated via `/version-manage`
- [ ] Commit messages follow Conventional Commits
- [ ] PR opened against `main` — never merged directly

---

## Important Rules

- If you ever find yourself on `main` with uncommitted changes, stash them, create a branch, and pop the stash — never commit on `main`
- Always pull before branching — stale branches cause merge conflicts
- One feature/fix per branch — keep branches focused and short-lived
- Delete branches after the PR is merged
