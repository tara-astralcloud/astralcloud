# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AstralCloud** (GitHub org: `tara-astralcloud`) is a self-hosted home cloud platform designed to run on k3s/k8s (initially Raspberry Pi nodes). This repo is the **platform core** — it contains the Dashboard UI, core services, and all infrastructure code. Independent apps live in their own repos under the `tara-astralcloud` org, publish Docker images, and are installed/uninstalled from the Dashboard via Helm.

## Repository Structure

```text
tara-astralcloud/
├── dashboard/           # Next.js frontend (platform hub + app marketplace UI)
├── services/
│   ├── file-storage/    # Go service
│   └── media-streaming/ # Go service
├── infra/
│   ├── terraform/       # Cluster provisioning
│   └── helm/            # Helm charts for core platform services
└── docs/
```

## Architecture

### Platform vs Apps

- **This repo** = platform core: Dashboard UI, Keycloak auth, File Storage, Media Streaming, Terraform, Helm charts
- **App repos** = independently developed apps under `tara-astralcloud` org that ship their own Helm chart + Docker image. The Dashboard calls the k8s/Helm API to install or uninstall them per user request.

### Core Services

| Service         | Tech     | Notes                                                    |
| --------------- | -------- | -------------------------------------------------------- |
| Auth            | Keycloak | Deployed as Helm chart, shared SSO/OIDC for all services |
| Dashboard UI    | Next.js  | Central hub and app marketplace                          |
| File Storage    | Go       | Owns its own database                                    |
| Media Streaming | Go       | Owns its own database                                    |

### Key Design Decisions

- **Polyglot:** Each service uses the language best suited to it. Go for resource-constrained backend services (low memory, fast startup on Pi). Next.js for the dashboard.
- **Database per service:** No shared databases. Each service chooses its own (PostgreSQL, SQLite, Redis, etc.) based on its needs.
- **Helm-based app lifecycle:** Apps are Helm charts. Install/uninstall from Dashboard triggers `helm install` / `helm uninstall` against the k3s/k8s cluster.
- **k3s/k8s agnostic:** Infra and Helm charts must work on both k3s (Pi) and standard k8s.

### Auth Flow

All services and apps delegate authentication to Keycloak via OIDC. The Dashboard handles the OAuth2 login flow. Service-to-service calls use Keycloak-issued JWTs.

## Development Commands

Commands will be added here as each service is built out.

### Dashboard UI (`dashboard/`)

```bash
npm install
npm run dev        # Start dev server
npm run build      # Production build
npm run lint       # Lint
npm test           # Run tests
```

### Go Services (`services/*`)

```bash
go build ./...                   # Build
go test ./...                    # All tests
go test ./... -run TestName      # Single test
go vet ./...                     # Lint
```

### Infrastructure (`infra/`)

```bash
terraform init
terraform plan
terraform apply

helm install astralcloud ./infra/helm/platform -n astralcloud
helm upgrade astralcloud ./infra/helm/platform -n astralcloud
```

## App Integration Contract

External apps that want to integrate with AstralCloud must:

1. Be hosted under the `tara-astralcloud` GitHub org
2. Publish a Docker image to a container registry (built for `linux/arm64`)
3. Ship a Helm chart with standard `values.yaml` (image, resources, ingress)
4. Use Keycloak OIDC for auth (client credentials provided at install time by the platform)

## Git & GitHub

- **Org:** [https://github.com/tara-astralcloud](https://github.com/tara-astralcloud)
- **Git email:** `ananthupmadhu@gmail.com`

Ensure your local git config uses the correct email before pushing:

```bash
git config user.email "ananthupmadhu@gmail.com"
```

## Deployment Target

- **Node:** Raspberry Pi (ARM64) — Docker images must be built for `linux/arm64`
- **Cluster:** k3s (dev/home) or k8s (production)
- **Namespace:** `astralcloud` (platform), per-app namespaces for installed apps

---

## Lessons Learned

When Claude makes a mistake, it must add a note here under the relevant section so the same mistake is not repeated. Each entry follows this format:

> **[Area] — What went wrong:** Short description. **Fix:** What to do instead.

### Git & GitHub

- **Helm path in docs — What went wrong:** `CLAUDE.md` used `./helm/platform` but the repo structure has the chart at `infra/helm/`. **Fix:** Always use `./infra/helm/platform` for Helm commands run from the repo root.
- **README committed after PR merged — What went wrong:** `README.md` was committed on a branch after the PR was already merged, so it never landed on `main`. **Fix:** Always verify a file exists on `main` after a PR merges (`git show main:<file>`) before assuming it is live.
- **Branch stale at skill invocation — What went wrong:** `/create-doc` was invoked while on `feat/code-review-skill`, which didn't have files merged from other branches. **Fix:** Always follow dev-practice: `git checkout main && git pull` before starting any new task.

### Terraform

- **`set {}` leaks secrets in Helm releases — What went wrong:** Used `set {}` to pass a sensitive variable to a `helm_release`. This exposes the value in plan output and Helm history. **Fix:** Always use `set_sensitive {}` for any secret value in a `helm_release` block.
- **`.terraform.lock.hcl` in gitignore — What went wrong:** A comment inside the `.gitignore` block said "commit this" but comments have no effect — the file was still ignored. **Fix:** Use `!.terraform.lock.hcl` negation to un-ignore it; always run `git check-ignore -v .terraform.lock.hcl` to verify.
- **`terraform refresh` is deprecated — What went wrong:** Used `terraform refresh` which is deprecated since Terraform 1.5. **Fix:** Use `terraform apply -refresh-only` instead.
- **S3 backend missing encryption and lock — What went wrong:** Remote state example omitted `encrypt = true` and `dynamodb_table`, which means plaintext state and no concurrency protection. **Fix:** Always include both in the S3 backend block.
- **Variable declared inline in resource file — What went wrong:** Placed a `variable` declaration inside a resource block example in `main.tf` context. **Fix:** All variable declarations belong in `variables.tf` — never inline.
- **`ssh_private_key_path` marked sensitive — What went wrong:** A file path is not a secret; marking it `sensitive = true` redacts it from plan output and makes debugging harder. **Fix:** Only mark the actual credential value sensitive, not the path to it.
- **Open-ended `required_version` — What went wrong:** Used `>= 1.6.0` for `required_version`, allowing any future major version. **Fix:** Use `~> 1.6` to constrain to the 1.x series.
- **Hardcoded IPs in module call — What went wrong:** Module call used literal IP strings instead of variables, embedding infrastructure config in code. **Fix:** Always pass `var.<name>` to module arguments; declare the variable in `variables.tf`.

### k3s / Helm

- **`sed -i ''` is macOS-only — What went wrong:** Used BSD `sed -i ''` syntax in a command targeting Raspberry Pi (Linux). This fails on GNU `sed`. **Fix:** Use `sed -i` (no empty-string argument) for Linux targets. Note macOS variant separately if needed.
- **`helm rollback` missing revision argument — What went wrong:** Wrote `helm rollback <release> -n <ns>` which always errors — Helm 3 requires a revision number as the second positional arg. **Fix:** Always include the revision: `helm rollback <release> <revision> -n <ns>`.
- **`L2Advertisement` YAML missing `spec` — What went wrong:** MetalLB `L2Advertisement` manifest had no `spec` field, causing schema validators to reject it. **Fix:** Always include `spec.ipAddressPools` referencing the pool name.
- **Helm repo not added before install — What went wrong:** `helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx` and MetalLB install commands omitted the `helm repo add` step, causing "repo not found" errors. **Fix:** Always show `helm repo add <name> <url> && helm repo update` before the first `helm install` from any repo.
- **Longhorn on Pi missing `open-iscsi` — What went wrong:** Longhorn install instructions omitted the required `open-iscsi` package that must be installed on every Pi node. Without it, volume attachments silently fail. **Fix:** Always include `sudo apt-get install -y open-iscsi && sudo systemctl enable --now iscsid` before the Longhorn Helm install.
- **`--version` omitted from Helm install commands — What went wrong:** MetalLB and Longhorn `helm upgrade --install` commands had no `--version` flag, violating the pinning rule. **Fix:** Always include an explicit `--version` flag on every `helm upgrade --install` command.
- **Flannel does not enforce NetworkPolicy — What went wrong:** Recommended `NetworkPolicy` as a security measure without noting that k3s's default Flannel CNI does not enforce it — policies are silently ignored. **Fix:** Always note this caveat; recommend switching to Calico or Cilium if NetworkPolicy is required.
- **`kubectl top` requires metrics-server — What went wrong:** Listed `kubectl top nodes/pods` as a Day-2 command without noting it requires metrics-server, which k3s does not install by default. **Fix:** Always note the metrics-server prerequisite alongside `kubectl top` commands.

### Next.js / Dashboard

- **`getServerSideProps` on App Router — What went wrong:** Mentioned `getServerSideProps` without specifying the router, causing ambiguity — this is a Pages Router API and wrong for App Router projects. **Fix:** Establish the router (Pages vs App) before writing any Next.js data-fetching code. Default to App Router (async Server Components) for new projects.

### Code Quality

- **Streaming vs `[]byte` contradiction — What went wrong:** A TDD example showed `Upload(ctx, name, []byte)` while the performance section mandated streaming via `io.Reader`. The two directly contradicted. **Fix:** Ensure all examples in a skill file are consistent with each other — if streaming is the standard, all examples must use `io.Reader`/`io.Writer`.
- **Error silently discarded in example code — What went wrong:** Graceful shutdown example called `srv.Shutdown(ctx)` without handling the returned error, violating the "no ignored errors" rule stated earlier in the same document. **Fix:** Every error return in example code must be handled, even in short snippets.
