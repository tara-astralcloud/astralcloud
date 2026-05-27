# Terraform Skill

Deep knowledge for writing, reviewing, and designing Terraform infrastructure for AstralCloud. Covers k3s/k8s provisioning on Raspberry Pi (ARM64), networking, storage, and Helm-based app lifecycle.

## Project Context

- **Infra directory:** `infra/terraform/`
- **Target:** Raspberry Pi nodes running k3s
- **Kubernetes distro:** k3s (lightweight, ARM64-compatible)
- **Helm namespace:** `astralcloud`
- **Provider versions:** always pinned in `required_providers`
- **State:** local for dev, remote for staging/prod

---

## Directory Layout

```text
infra/terraform/
├── main.tf                    # Providers, backend, top-level resources
├── variables.tf               # All input variable declarations
├── outputs.tf                 # Output values
├── versions.tf                # Terraform and provider version constraints
├── terraform.tfvars.example   # Example values — committed to repo
├── terraform.tfvars           # Real values — gitignored
└── modules/
    ├── k3s-node/              # k3s node provisioning (SSH, install, configure)
    ├── networking/            # MetalLB, ingress, DNS
    └── storage/               # Persistent volume provisioning
```

---

## Core Design Principles

- **Never hardcode secrets** — declare all secrets as `sensitive = true` variables, pass values via `terraform.tfvars` (gitignored) or environment variables (`TF_VAR_*`)
- **Pin provider versions** — use `~>` for minor-version flexibility (e.g. `~> 2.13` allows 2.13.x but not 3.x); never use open-ended `>=`
- **Commit `.terraform.lock.hcl`** — this file pins provider checksums for reproducible installs across machines; never gitignore it
- **Separate `variables.tf`** — all variable declarations belong in `variables.tf`, never inline in `main.tf` or resource files
- **Remote state for production** — local `terraform.tfstate` is only acceptable for dev; staging/prod must use a remote backend with state locking
- **Tag all resources** — every resource should carry `project = "astralcloud"` and `env = var.environment` labels/tags
- **Modules for reuse** — any resource group used more than once belongs in a module; single-use resource groups stay in root

---

## Provider Setup

### versions.tf

```hcl
terraform {
  required_version = "~> 1.6"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
```

### main.tf — provider blocks

```hcl
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}
```

---

## Variables

All variable declarations go in `variables.tf`. Use `validation` blocks to catch bad inputs early. Mark secrets `sensitive = true` — Terraform redacts them from plan output.

```hcl
# variables.tf

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod"
  }
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for platform resources"
  type        = string
  default     = "astralcloud"
}

variable "ingress_host" {
  description = "Public hostname for the AstralCloud ingress (e.g. astralcloud.local)"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "server_node_ip" {
  description = "IP address of the k3s server (control-plane) node"
  type        = string
}

variable "agent_node_ips" {
  description = "IP addresses of k3s agent (worker) nodes"
  type        = list(string)
  default     = []
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for node provisioning"
  type        = string
  # Note: the path itself is not sensitive — only the key content is.
  # If passing key content directly as a string variable, mark that variable sensitive instead.
}
```

---

## Kubernetes Resources

### Namespace

```hcl
resource "kubernetes_namespace" "astralcloud" {
  metadata {
    name = var.namespace
    labels = {
      project = "astralcloud"
      env     = var.environment
    }
  }
}
```

### Secret — always use `sensitive` variables, never literal values

```hcl
# Variable declared in variables.tf (see above)
resource "kubernetes_secret" "keycloak_admin" {
  metadata {
    name      = "keycloak-admin"
    namespace = kubernetes_namespace.astralcloud.metadata[0].name
  }

  data = {
    admin-password = var.keycloak_admin_password
  }
}
```

### ConfigMap

```hcl
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.astralcloud.metadata[0].name
  }

  data = {
    environment = var.environment
    log_level   = "info"
  }
}
```

---

## Helm Releases

### Key rules for `helm_release`

- Always pin `version` — never omit it or use floating references
- Pass secrets via `set_sensitive {}`, not `set {}` — `set {}` exposes values in plan output and Helm release history
- Use `depends_on` to ensure the namespace exists before the release
- For environment-specific values, use per-environment `values` files rather than many `set {}` blocks

```hcl
resource "helm_release" "keycloak" {
  name       = "keycloak"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  version    = "21.0.0"
  namespace  = kubernetes_namespace.astralcloud.metadata[0].name

  set_sensitive {
    name  = "auth.adminPassword"
    value = var.keycloak_admin_password
  }

  set {
    name  = "replicaCount"
    value = "1"
  }

  depends_on = [kubernetes_namespace.astralcloud]
}
```

For the AstralCloud platform chart (local path):

```hcl
resource "helm_release" "astralcloud" {
  name      = "astralcloud"
  chart     = "${path.module}/../helm/platform"
  namespace = kubernetes_namespace.astralcloud.metadata[0].name
  # Local chart: version is read from Chart.yaml — no version pin needed here

  values = [
    file("${path.module}/helm-values/${var.environment}.yaml")
  ]

  depends_on = [kubernetes_namespace.astralcloud]
}
```

---

## Outputs

```hcl
# outputs.tf

output "namespace" {
  description = "Kubernetes namespace for the platform"
  value       = kubernetes_namespace.astralcloud.metadata[0].name
}

output "keycloak_url" {
  description = "Keycloak admin console URL"
  value       = "https://${var.ingress_host}/auth"
}
```

---

## Modules

### Structure

Every module must have `main.tf`, `variables.tf`, `outputs.tf`, and a `README.md` (generated with `terraform-docs`).

```text
modules/k3s-node/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

### Module variables — always include `description`

```hcl
# modules/k3s-node/variables.tf

variable "node_ip" {
  description = "IP address of the Raspberry Pi node"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for provisioning"
  type        = string
  default     = "pi"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  # The path is not sensitive — only the key content is.
}

variable "k3s_version" {
  description = "k3s version to install (keep in sync with cluster)"
  type        = string
  default     = "v1.32.3+k3s1"
}

variable "role" {
  description = "Node role: server (control-plane) or agent (worker)"
  type        = string

  validation {
    condition     = contains(["server", "agent"], var.role)
    error_message = "role must be server or agent"
  }
}
```

### Calling a module — use variables, never hardcode IPs

```hcl
module "pi_server" {
  source = "./modules/k3s-node"

  node_ip              = var.server_node_ip
  ssh_private_key_path = var.ssh_private_key_path
  # k3s_version omitted — uses module default (v1.32.3+k3s1)
  role = "server"
}

module "pi_agents" {
  for_each = toset(var.agent_node_ips)
  source   = "./modules/k3s-node"

  node_ip              = each.value
  ssh_private_key_path = var.ssh_private_key_path
  # k3s_version omitted — uses module default; override via var.k3s_version if needed
  role = "agent"
}
```

---

## State Management

### Local state (dev only)

No backend block needed. State lives in `terraform.tfstate` locally. Never commit this file.

### Remote state (staging / prod)

Remote state requires encryption and locking. Without `encrypt = true`, state (which contains secret values) is stored in plaintext. Without a lock table, concurrent applies corrupt state.

For a home-lab setup, use Terraform Cloud free tier (simplest) or an HTTP backend backed by a local MinIO instance:

```hcl
# Terraform Cloud (recommended for home-lab)
terraform {
  cloud {
    organization = "astralcloud"
    workspaces {
      name = "platform"
    }
  }
}
```

If using AWS S3 (cloud/production), remote state requires encryption and a DynamoDB lock table. Without `encrypt = true`, state is stored in plaintext. Without `dynamodb_table`, concurrent applies corrupt state:

```hcl
terraform {
  backend "s3" {
    bucket         = "astralcloud-tfstate"
    key            = "platform/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "astralcloud-tfstate-lock"
  }
}
```

---

## .gitignore for Terraform

```gitignore
# Terraform — add to repo root .gitignore
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
!terraform.tfvars.example
tfplan
crash.log
override.tf
override.tf.json
```

**Never gitignore `.terraform.lock.hcl`** — commit it. It pins provider checksums so all contributors and CI use identical provider binaries.

After adding the `*.tfvars` rule, verify both that secrets are ignored AND the example is not:

```bash
git check-ignore -v terraform.tfvars
# should print: .gitignore:N:*.tfvars   terraform.tfvars

git check-ignore -v terraform.tfvars.example
# should print nothing (not ignored)
```

---

## ARM64 / Raspberry Pi Considerations

- Confirm ARM64 support for every Helm chart before deploying — Bitnami charts have supported ARM64 since mid-2022; older community charts may ship x86-only init containers
- k3s bundles containerd — no Docker daemon needed on nodes
- For a local image registry on Pi: run `registry:2` as a k3s `HelmChart` manifest; it uses far less memory than Harbor
- Avoid `hostPort` on Pi — use MetalLB + LoadBalancer services instead to keep ingress predictable across reboots
- k3s agent nodes need at minimum 512 MB RAM; keep resource `requests` on all pods conservative

---

## Review Checklist

When reviewing Terraform code, check:

- [ ] `sensitive = true` on all secret variables
- [ ] `set_sensitive {}` used (not `set {}`) for secret Helm values
- [ ] No hardcoded IPs, secrets, or account IDs in `.tf` files
- [ ] Provider versions pinned with `~>` in `versions.tf`
- [ ] `.terraform.lock.hcl` is committed (not gitignored)
- [ ] Remote state uses a locking backend: Terraform Cloud workspace, or S3 + DynamoDB (`encrypt = true` + `dynamodb_table`)
- [ ] `depends_on` used where creation order matters (e.g. namespace before Helm release)
- [ ] All variables have `description` fields
- [ ] Module outputs expose the values callers need — no reaching into module internals
- [ ] `terraform validate` passes cleanly
- [ ] `terraform fmt -recursive` applied — all HCL is formatted

---

## Security Rules

- Never store secrets in `.tf` files or any `.tfvars` file committed to git
- Rotate credentials immediately after any accidental exposure
- Use least-privilege RBAC for the service account Terraform uses to apply resources
- For production: use Vault or Terraform Cloud for secret injection instead of tfvars files
- `terraform destroy` must never be run autonomously — always require explicit user confirmation; treat it like a destructive git operation

---

## Important Notes

- `terraform refresh` is deprecated since Terraform 1.5 — use `terraform apply -refresh-only` instead
- `terraform plan -out=tfplan` followed by `terraform apply tfplan` ensures what you reviewed is exactly what gets applied
- When adding a new provider, add it to `versions.tf` first, then run `terraform init` — never `terraform init -upgrade` without understanding what will change
- Use `terraform-docs` to keep module `README.md` files current with variable and output changes
