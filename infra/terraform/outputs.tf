output "server_ip" {
  description = "IP address of the k3s server (control-plane) node"
  value       = module.server.node_ip
}

output "agent_ips" {
  description = "IP addresses of k3s agent (worker) nodes"
  value       = [for m in module.agents : m.node_ip]
}

output "kubeconfig_command" {
  description = "Commands to copy kubeconfig from the server to your local machine"
  value       = <<-EOT
    scp ${var.ssh_user}@${var.server_node_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config
    sed -i 's|https://127.0.0.1:6443|https://${var.server_node_ip}:6443|g' ~/.kube/config
    chmod 600 ~/.kube/config
    kubectl get nodes
  EOT
}
