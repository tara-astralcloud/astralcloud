output "metallb_installed" {
  description = "MetalLB release installed"
  value       = "metallb 0.14.9 in metallb-system"
}

output "ingress_nginx_installed" {
  description = "ingress-nginx release installed"
  value       = "ingress-nginx 4.10.1 in ingress-nginx"
}

output "keycloak_installed" {
  description = "Keycloak release installed"
  value       = "keycloak codecentric/keycloakx 7.2.0 in keycloak"
}

output "dashboard_installed" {
  description = "Dashboard release installed"
  value       = "dashboard local chart 0.2.0 in astralcloud"
}
