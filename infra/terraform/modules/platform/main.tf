locals {
  metallb_values_file    = "${var.helm_values_dir}/metallb/values.yaml"
  metallb_crds_file      = "${var.helm_values_dir}/metallb/crds/ip-address-pool.yaml"
  ingress_nginx_values   = "${var.helm_values_dir}/ingress-nginx/values.yaml"
  keycloak_values_file   = "${var.helm_values_dir}/keycloak/values.yaml"
  keycloak_postgres_file = "${var.helm_values_dir}/keycloak/postgres.yaml"
}

# ── 1. MetalLB ───────────────────────────────────────────────────────────────
# L2 mode only (no BGP). IPAddressPool + L2Advertisement applied after controller
# is ready — the MetalLB webhook validates these custom resources.

resource "null_resource" "metallb" {
  triggers = { force = var.force_reprovision }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      helm repo add metallb https://metallb.github.io/metallb
      helm repo update metallb
      helm upgrade --install metallb metallb/metallb \
        --version 0.14.9 \
        --namespace metallb-system \
        --create-namespace \
        --wait \
        --timeout 5m \
        -f ${local.metallb_values_file}
      kubectl rollout status deployment/metallb-controller \
        -n metallb-system --timeout=3m
      kubectl apply -f ${local.metallb_crds_file}
    EOT
  }
}

# ── 2. ingress-nginx ─────────────────────────────────────────────────────────
# LoadBalancer type — MetalLB assigns the first IP from local-pool (192.168.0.200).

resource "null_resource" "ingress_nginx" {
  triggers   = { force = var.force_reprovision }
  depends_on = [null_resource.metallb]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo update ingress-nginx
      helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --version 4.10.1 \
        --namespace ingress-nginx \
        --create-namespace \
        --wait \
        --timeout 5m \
        -f ${local.ingress_nginx_values}
    EOT
  }
}

# ── 3. Keycloak ──────────────────────────────────────────────────────────────
# Uses codecentric/keycloakx chart (quay.io/keycloak/keycloak image — not Bitnami).
# PostgreSQL is deployed as a plain StatefulSet (postgres:16-alpine) before Helm.
# Password passed via environment block — never appears in Terraform state.
# IMPORTANT: Do NOT add var.keycloak_admin_password to triggers — trigger values
# are stored as plaintext in terraform.tfstate.

resource "null_resource" "keycloak" {
  triggers   = { force = var.force_reprovision }
  depends_on = [null_resource.ingress_nginx]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      KEYCLOAK_ADMIN_PASSWORD = var.keycloak_admin_password
    }
    command = <<-EOT
      set -euo pipefail

      # Create namespace and shared secret (used by both postgres and keycloak)
      kubectl create namespace keycloak --dry-run=client -o yaml | kubectl apply -f -
      kubectl create secret generic keycloak-secret \
        --namespace keycloak \
        --from-literal=password="$KEYCLOAK_ADMIN_PASSWORD" \
        --dry-run=client -o yaml | kubectl apply -f -

      # Deploy postgres StatefulSet (official postgres:16-alpine)
      kubectl apply -f ${local.keycloak_postgres_file}
      kubectl rollout status statefulset/keycloak-postgres \
        -n keycloak --timeout=3m

      # Deploy Keycloak via codecentric/keycloakx
      helm repo add codecentric https://codecentric.github.io/helm-charts
      helm repo update codecentric
      helm upgrade --install keycloak codecentric/keycloakx \
        --version 7.2.0 \
        --namespace keycloak \
        --wait \
        --timeout 10m \
        -f ${local.keycloak_values_file}
    EOT
  }
}
