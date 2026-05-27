# Code Review Skill

Review code and files in the AstralCloud project for correctness, security, style, and consistency.

## When to Invoke

- Before opening a PR — catch issues early
- When asked to "review", "check", or "look over" code or files
- After making changes — verify nothing was broken or missed

---

## Review Scope

When invoked, determine what to review based on context:

1. **Current diff (default):** Changes staged or unstaged since the last commit
2. **Specific file(s):** When the user names a file or directory
3. **Entire service:** When asked to review a service directory (e.g. `services/file-storage/`)
4. **PR diff:** When asked to review an open PR

---

## Review Process

### Step 1 — Gather the diff or file list

**For current changes:**

```bash
git diff HEAD
git diff --cached
git status --short
```

**For a specific file or directory:**

```bash
# Read the file(s) directly
```

**For an open PR:**

```bash
gh pr diff <PR number or URL>
```

### Step 2 — Read relevant source files

Before reviewing, read the file(s) in full to understand context — don't review diffs in isolation.

### Step 3 — Apply review checklist

Go through each category below and flag any issues found.

### Step 4 — Spawn a reviewer agent for a second opinion

After completing your own review, spawn a `code-reviewer` sub-agent to get an independent review of the same diff/files. Brief it with:

- The files or diff content
- The language/stack (Go, Next.js, YAML, etc.)
- The AstralCloud context (ARM64 target, Keycloak auth, k3s/k8s)

Merge the agent's findings with yours. If the agent finds issues you missed, include them. Deduplicate overlapping findings.

### Step 5 — Present combined findings and ask for user approval

Show the merged review output (grouped by severity per the Output Format below).

Then **explicitly ask the user for approval** before proceeding:

> "Review complete. Please approve to continue, or let me know what to fix."

**Do not proceed to commit or push until the user explicitly approves** (e.g. "LGTM", "looks good", "approved", "go ahead").

If the user requests fixes: apply them, then re-run the review from Step 1.

---

## Review Checklist

### Correctness

- [ ] Logic is correct and handles edge cases
- [ ] No off-by-one errors, nil dereferences, or unhandled errors
- [ ] Return values and error paths are properly handled
- [ ] Tests cover the changed behaviour (or note that tests are missing)

### Security

- [ ] No secrets, tokens, or credentials in code or config files
- [ ] No SQL injection, command injection, or XSS vectors
- [ ] Auth checks are present on protected routes/endpoints
- [ ] File paths and user inputs are validated/sanitised
- [ ] No `GITHUB_TOKEN` or other secrets logged

### Go-specific (for services/)

- [ ] Errors are wrapped with context (`fmt.Errorf("...: %w", err)`)
- [ ] No goroutine leaks — channels and goroutines are always cleaned up
- [ ] Context is threaded through long operations
- [ ] No `panic` in production paths
- [ ] Exported types/functions have doc comments

### Next.js / TypeScript-specific (for dashboard/)

- [ ] No `any` types — use proper TypeScript types
- [ ] `useEffect` dependencies are correct
- [ ] No raw `dangerouslySetInnerHTML` without sanitisation
- [ ] API calls handle loading and error states
- [ ] Environment variables accessed via `process.env.NEXT_PUBLIC_*` only on client

### CI / Workflow files (.github/workflows/)

- [ ] Actions pinned to a specific version (e.g. `actions/checkout@v4`)
- [ ] No secrets hardcoded — use `${{ secrets.NAME }}`
- [ ] Docker builds target `linux/arm64`
- [ ] `permissions:` block is scoped to minimum needed (`contents: write`, not broad access)

### Helm / Infra (infra/)

- [ ] Resource limits (`requests` and `limits`) set on all containers
- [ ] Liveness and readiness probes defined
- [ ] No hardcoded namespaces — use `{{ .Release.Namespace }}`
- [ ] Secrets referenced from k8s Secrets, not `values.yaml` plaintext

### General

- [ ] No dead code or commented-out blocks left behind
- [ ] File follows the project's conventions (naming, structure, formatting)
- [ ] CHANGELOG.md updated if this is a user-facing change
- [ ] VERSION bumped if appropriate

---

## Output Format

Report findings grouped by severity:

### 🔴 Must Fix

Issues that are bugs, security problems, or broken behaviour. Block the PR until resolved.

### 🟡 Should Fix

Code quality issues, missing error handling, or style violations. Fix before merging if possible.

### 🟢 Suggestions

Non-blocking improvements — better naming, refactor opportunities, test ideas.

If there are no issues in a category, omit it entirely. End with a one-line verdict:

> **Overall:** Ready to merge / Needs fixes before merge

---

## After Review

- If issues were found: describe each clearly with the file, line (if known), and a suggested fix
- If the review is clean: confirm it and offer to open the PR via `/git-manage`
- Never auto-fix code during a review — report findings only, unless the user explicitly asks to fix

---

## Important Rules

- Always read the full file before commenting on a diff — partial context causes false positives
- Do not comment on formatting that Prettier/gofmt already handles automatically
- Focus on what matters: bugs, security, missing tests, and logic errors
- Keep feedback specific and actionable — cite file and line where possible
