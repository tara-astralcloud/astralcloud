variable "k3s_version" {
  description = "k3s version to install on all nodes (e.g. v1.32.3+k3s1)"
  type        = string
  default     = "v1.32.3+k3s1"

  validation {
    condition     = can(regex("^v\\d+\\.\\d+\\.\\d+\\+k3s\\d+$", var.k3s_version))
    error_message = "k3s_version must match vMAJOR.MINOR.PATCH+k3sN (e.g. v1.32.3+k3s1)"
  }
}

variable "server_node_ip" {
  description = "IP address of the k3s server (control-plane) node"
  type        = string

  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.server_node_ip))
    error_message = "server_node_ip must be a valid IPv4 address"
  }
}

variable "agent_node_ips" {
  description = "IP addresses of k3s agent (worker) nodes — leave empty for single-node"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.agent_node_ips) == length(toset(var.agent_node_ips))
    error_message = "agent_node_ips must not contain duplicate IP addresses"
  }
}

variable "ssh_user" {
  description = "SSH user on the Raspberry Pi nodes"
  type        = string
  default     = "pi"
}

variable "ssh_password" {
  description = "SSH password for Pi nodes — pass via TF_VAR_ssh_password env var, never in .tfvars"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password — pass via TF_VAR_keycloak_admin_password, never in .tfvars"
  type        = string
  sensitive   = true
}

variable "metallb_ip_range" {
  description = "MetalLB L2 IP address pool range (e.g. 192.168.0.200-192.168.0.220)"
  type        = string
  default     = "192.168.0.200-192.168.0.220"

  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}-(\\d{1,3}\\.){3}\\d{1,3}$", var.metallb_ip_range))
    error_message = "metallb_ip_range must be in the form A.B.C.D-A.B.C.E"
  }
}

variable "platform_force_reprovision" {
  description = "Increment to force platform Helm resources to re-run after a values change"
  type        = string
  default     = "0"
}

variable "dashboard_client_secret" {
  description = "Keycloak OIDC client secret for the dashboard — pass via TF_VAR_dashboard_client_secret, never in .tfvars"
  type        = string
  sensitive   = true
}

variable "dashboard_auth_secret" {
  description = "Auth.js secret for JWT signing — pass via TF_VAR_dashboard_auth_secret, never in .tfvars"
  type        = string
  sensitive   = true
}
