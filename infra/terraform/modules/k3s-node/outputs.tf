output "node_ip" {
  description = "IP address of this node"
  value       = var.node_ip
}

output "role" {
  description = "Role of this node: server or agent"
  value       = var.role
}

output "node_token" {
  description = "k3s node token (server nodes only) — pass to agent modules to join the cluster"
  value       = var.role == "server" ? data.external.node_token[0].result["token"] : ""
  sensitive   = true
}
