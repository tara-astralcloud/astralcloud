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
