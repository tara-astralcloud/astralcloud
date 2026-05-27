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
}

variable "k3s_version" {
  description = "k3s version to install — keep in sync across all nodes"
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

variable "server_ip" {
  description = "IP of the k3s server node — required when role is agent"
  type        = string
  default     = ""
}

variable "server_token" {
  description = "k3s node token from the server — required when role is agent"
  type        = string
  sensitive   = true
  default     = ""
}
