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
