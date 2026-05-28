module "server" {
  source = "./modules/k3s-node"

  node_ip      = var.server_node_ip
  ssh_user     = var.ssh_user
  ssh_password = var.ssh_password
  k3s_version  = var.k3s_version
  role         = "server"
}

module "agents" {
  for_each = toset(var.agent_node_ips)
  source   = "./modules/k3s-node"

  node_ip      = each.value
  ssh_user     = var.ssh_user
  ssh_password = var.ssh_password
  k3s_version  = var.k3s_version
  role         = "agent"
  server_ip    = var.server_node_ip
  server_token = module.server.node_token
}

module "platform" {
  source = "./modules/platform"

  server_node_ip          = var.server_node_ip
  metallb_ip_range        = var.metallb_ip_range
  keycloak_admin_password = var.keycloak_admin_password
  force_reprovision       = var.platform_force_reprovision
  helm_values_dir         = "${path.module}/../helm"
  dashboard_client_secret = var.dashboard_client_secret
  dashboard_auth_secret   = var.dashboard_auth_secret

  depends_on = [module.server]
}
