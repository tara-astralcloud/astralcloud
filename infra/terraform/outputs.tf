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

output "ingress_nginx_ip" {
  description = "Command to retrieve the ingress-nginx LoadBalancer IP assigned by MetalLB"
  value       = "kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}

output "keycloak_url" {
  description = "Keycloak admin console URL — add MetalLB IP to /etc/hosts as keycloak.astralcloud.local"
  value       = "http://keycloak.astralcloud.local/auth/admin"
}
