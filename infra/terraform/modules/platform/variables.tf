variable "server_node_ip" {
  description = "IP address of the k3s server node"
  type        = string
}

variable "metallb_ip_range" {
  description = "MetalLB L2 IP address pool range (e.g. 192.168.0.200-192.168.0.220)"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password — injected via environment block, never stored in triggers or state"
  type        = string
  sensitive   = true
}

variable "force_reprovision" {
  description = "Increment to force all helm resources to re-run (e.g. after a values change)"
  type        = string
  default     = "0"
}

variable "helm_values_dir" {
  description = "Absolute path to the infra/helm/ directory containing per-chart values.yaml files"
  type        = string
}
