# Development Practice Skill

Enforce the AstralCloud development workflow: test-driven development, code quality gates, and performance/scalability standards — always starting from a clean, up-to-date main branch.

## Golden Rule

**Never make changes directly on `main`.** Every change — no matter how small — follows this workflow:

```
checkout main → pull latest → create branch → write tests first → implement → quality gates → /git-manage
```

---

## Step-by-Step Workflow

### Before Making ANY Change

**1. Switch to main and pull latest**

```bash
git checkout main
git pull origin main
```

If there are uncommitted changes, stash them first:

```bash
git stash
git pull origin main
git stash pop
```

**2. Create a new branch** using naming conventions from `/git-manage`:

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
git branch --show-current   # verify — never proceed on main
```

---

## Test-Driven Development (TDD)

**Write the test before writing the implementation.** Every new function, handler, or component must follow Red → Green → Refactor.

### The TDD Cycle

```
1. RED    — write a failing test that describes the desired behaviour
2. GREEN  — write the minimum code to make the test pass
3. REFACTOR — clean up without breaking the test
```

Never skip step 1. If a test is hard to write, that signals a design problem — fix the design, not the test.

### Go Services — TDD Pattern

```go
// Step 1: Write the test first (RED)
func TestUploadFile_ValidInput_ReturnsID(t *testing.T) {
    svc := NewFileService(fakeStorage{})
    id, err := svc.Upload(context.Background(), "test.txt", strings.NewReader("content"))
    require.NoError(t, err)
    assert.NotEmpty(t, id)
}

// Step 2: Run — test must FAIL before implementing
// go test ./... -run TestUploadFile_ValidInput_ReturnsID

// Step 3: Implement the minimum to pass (GREEN)
// Step 4: Refactor — clean up, then verify test still passes
```

Test naming: `TestFunctionName_Condition_ExpectedOutcome`

Always run tests with the race detector:

```bash
go test ./... -race -coverprofile=coverage.out
go tool cover -func=coverage.out   # review coverage per function
```

### Next.js / TypeScript — TDD Pattern

```typescript
// Step 1: Write the test first (RED)
describe("FileUpload", () => {
  it("calls onSuccess with file ID after upload", async () => {
    const onSuccess = vi.fn();
    render(<FileUpload onSuccess={onSuccess} />);
    await userEvent.upload(screen.getByLabelText("File"), testFile);
    await waitFor(() => expect(onSuccess).toHaveBeenCalledWith(expect.any(String)));
  });
});

// Step 2: Run — test must FAIL
// Step 3: Implement the component
// Step 4: Refactor
```

Run tests:

```bash
npm test                  # all tests
npm test -- --watch       # watch mode during development
npm test -- --coverage    # coverage report
```

### Test Coverage Targets

| Layer                      | Minimum coverage                |
| -------------------------- | ------------------------------- |
| Go service — core logic    | 80%                             |
| Go service — HTTP handlers | 70%                             |
| Next.js — components       | 70%                             |
| Next.js — utilities/hooks  | 80%                             |
| Helm / Terraform           | lint + validate (no unit tests) |

Coverage is a floor, not a target — aim higher on critical paths (auth, data mutations).

---

## Code Quality Standards

### Go Services

**Error handling — always wrap with context:**

```go
// WRONG
return nil, err

// RIGHT
return nil, fmt.Errorf("upload %s: %w", filename, err)
```

**No naked returns, no ignored errors:**

```go
// WRONG
result, _ := doSomething()

// RIGHT
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doSomething: %w", err)
}
```

**Context threading — pass ctx to every I/O call:**

```go
func (s *Service) Upload(ctx context.Context, name string, r io.Reader) (string, error) {
    if err := s.storage.Put(ctx, name, r); err != nil {
        return "", fmt.Errorf("storage put %s: %w", name, err)
    }
    return generateID(), nil
}
```

**Interface-driven design — depend on interfaces, not concrete types:**

```go
type Storage interface {
    Put(ctx context.Context, key string, r io.Reader) error
    Get(ctx context.Context, key string) (io.ReadCloser, error)
    Delete(ctx context.Context, key string) error
}
```

This makes unit testing with fakes trivial and decouples implementation from callers.

**Run quality checks before every commit:**

```bash
go vet ./...
go test ./... -race
staticcheck ./...     # if available
```

### Next.js / TypeScript

**No `any` — use proper types:**

```typescript
// WRONG
const handleResponse = (data: any) => { ... }

// RIGHT
const handleResponse = (data: UploadResponse) => { ... }
```

**Prefer named exports over default exports** — easier to refactor and grep.

**Separate concerns — keep components focused:**

- UI components: render only, no data fetching
- Custom hooks: data fetching, state, side effects
- Utilities: pure functions, no React

**Run quality checks before every commit:**

```bash
npm run lint
npx tsc --noEmit    # type check without emitting files
npm test
```

### Universal Rules (all code)

- Functions do one thing — if you need "and" to describe it, split it
- Keep functions short — if a Go function exceeds ~40 lines or a React component exceeds ~100, it likely needs splitting
- Meaningful names — variables, functions, and types should read like prose
- No commented-out code — use git history instead
- No TODO comments in committed code — open a Jira/GitHub issue instead

---

## Performance Standards

Design for the Raspberry Pi constraint: limited CPU (ARM Cortex-A72/A76) and RAM (2–8 GB shared across all services).

### Go Services

- **Avoid unnecessary allocations in hot paths** — reuse buffers, use `sync.Pool` for frequently allocated objects
- **Stream large files** — never load a full file into memory; use `io.Reader`/`io.Writer` pipelines
- **Use connection pools** — database and HTTP client connections must be pooled, never created per-request
- **Set timeouts on all I/O** — HTTP clients, DB queries, and context deadlines must always have a timeout
- **Benchmark critical paths:**

```bash
go test -bench=. -benchmem ./...
```

If a benchmark regresses by more than 10%, treat it as a bug.

### Next.js Dashboard

- **No client-side data fetching on initial load** — use async Server Components (App Router) to avoid waterfall requests; data fetching happens on the server before the page is sent to the client
- **Lazy-load heavy components** — use `next/dynamic` for chart libraries, editors, and anything not needed on first paint
- **Optimise images** — always use `next/image`; never raw `<img>` tags
- **Memoize expensive computations** — `useMemo` for derived state, `useCallback` for stable callbacks passed to children
- **Bundle size discipline** — run `npm run build` and check bundle sizes; flag any page chunk over 250 KB for review

### Resource Limits on Pi

Every Kubernetes workload must declare resource requests and limits. These are the baselines — adjust based on observed usage:

| Service         | CPU request | CPU limit | Memory request | Memory limit |
| --------------- | ----------- | --------- | -------------- | ------------ |
| file-storage    | 100m        | 500m      | 128Mi          | 256Mi        |
| media-streaming | 200m        | 1000m     | 256Mi          | 512Mi        |
| dashboard       | 100m        | 500m      | 128Mi          | 256Mi        |
| keycloak        | 250m        | 1000m     | 512Mi          | 1Gi          |

---

## Scalability Standards

Design every service to scale horizontally (multiple replicas) even if initially deployed with one.

### Go Services

- **Stateless handlers** — no in-process session state; use the database or Redis
- **Idempotent writes** — PUT/POST operations should be safe to retry without side effects
- **Graceful shutdown** — listen for `SIGTERM`, drain in-flight requests, then exit:

```go
srv := &http.Server{Addr: ":8080", Handler: mux}
go func() {
    if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
        log.Printf("listen: %v", err)
    }
}()

quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGTERM, syscall.SIGINT)
<-quit

ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
defer cancel()
if err := srv.Shutdown(ctx); err != nil {
    log.Printf("shutdown: %v", err)
}
```

- **Database migrations are backward-compatible** — new columns are nullable or have defaults; never drop/rename a column in the same migration as the code change that removes it

### Kubernetes / Helm

- Set `PodDisruptionBudget` for any service with more than one replica
- Use `readinessProbe` to prevent traffic reaching pods that are not yet ready
- Use `livenessProbe` to restart pods that are stuck
- Avoid `hostPath` volumes — they tie pods to a specific node and block rescheduling

---

## Making Changes

- Write the test first — commit the test in a separate commit from the implementation when the change is non-trivial
- Commit incrementally — one logical change per commit, not a giant squash at the end
- Each commit must leave the codebase in a working, tested state

---

## Pre-PR Checklist

Run through every item before invoking `/git-manage`:

### All changes

- [ ] Started from `main` with latest code pulled
- [ ] All changes are on a named branch (not `main`)
- [ ] Tests written before implementation (TDD cycle followed)
- [ ] All tests pass: `go test ./... -race` or `npm test`
- [ ] Linting passes: `go vet ./...` or `npm run lint`
- [ ] No `any` types (TypeScript) or ignored errors (Go)

### Go services

- [ ] Coverage meets the target for the changed package
- [ ] Benchmarks run — no regressions
- [ ] Context passed through all I/O calls
- [ ] Errors wrapped with context using `fmt.Errorf("...: %w", err)`

### Next.js dashboard

- [ ] TypeScript compiles: `npx tsc --noEmit`
- [ ] No raw `<img>` tags — use `next/image`
- [ ] No `any` types
- [ ] New page chunks under 250 KB

### Kubernetes / Helm

- [ ] Resource `requests` and `limits` set on all containers
- [ ] `livenessProbe` and `readinessProbe` defined
- [ ] Helm release chart `version` is pinned (never omit or use a floating reference)
- [ ] `helm lint` passes
- [ ] `helm template ... --debug > /dev/null` passes

### Version & commit

- [ ] `VERSION` and `CHANGELOG.md` updated via `/version-manage`
- [ ] Commit messages follow Conventional Commits
- [ ] PR opened against `main` via `/git-manage`

---

## Important Rules

- **TDD is non-negotiable** — never commit implementation code without a corresponding test
- **Tests are first-class code** — apply the same quality and naming standards to tests as to production code
- If you find yourself on `main` with uncommitted changes: stash, create a branch, pop the stash — never commit on `main`
- Always pull before branching — stale branches cause merge conflicts
- One feature/fix per branch — keep branches focused and short-lived
- Delete branches after the PR is merged
