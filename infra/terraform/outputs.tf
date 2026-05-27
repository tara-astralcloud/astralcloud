output "server_ip" {
  description = "IP address of the k3s server (control-plane) node"
  value       = module.server.node_ip
}

output "agent_ips" {
  description = "IP addresses of k3s agent (worker) nodes"
  value       = [for m in module.agents : m.node_ip]
}

output "verify_cluster" {
  description = "Command to verify the cluster is up after terraform apply"
  value       = "kubectl get nodes"
}
