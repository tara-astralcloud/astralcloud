locals {
  is_server = var.role == "server"
}

# Provision the k3s server (control-plane) node
resource "null_resource" "k3s_server" {
  count = local.is_server ? 1 : 0

  triggers = {
    node_ip     = var.node_ip
    k3s_version = var.k3s_version
  }

  connection {
    type     = "ssh"
    host     = var.node_ip
    user     = var.ssh_user
    password = var.ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      # Install k3s server; Traefik disabled — ingress-nginx added in a later PR
      # --write-kubeconfig-mode 644 lets the pi user scp the kubeconfig without sudo
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' sh -s - server --disable traefik --write-kubeconfig-mode 644",
      # Wait up to 3 minutes for the node to become Ready
      "n=0; until sudo k3s kubectl get nodes 2>/dev/null | grep -q ' Ready'; do sleep 5; n=$((n+1)); [ $n -lt 36 ] || { echo 'k3s did not become ready after 3 minutes' >&2; exit 1; }; done",
    ]
  }
}

# Copy kubeconfig to the local machine and patch the server address
resource "null_resource" "kubeconfig" {
  count = local.is_server ? 1 : 0

  depends_on = [null_resource.k3s_server]

  triggers = {
    node_ip = var.node_ip
  }

  provisioner "local-exec" {
    # SSHPASS is set from TF_VAR_ssh_password which Terraform exports into the env
    command     = <<-EOT
      mkdir -p ~/.kube
      SSHPASS="${var.ssh_password}" sshpass -e scp -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null \
        ${var.ssh_user}@${var.node_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config
      sed -i '' 's|https://127.0.0.1:6443|https://${var.node_ip}:6443|g' ~/.kube/config
      chmod 600 ~/.kube/config
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Read the node token so agent nodes can join the cluster.
# python3 safely encodes the token as JSON, avoiding issues with special chars.
data "external" "node_token" {
  count = local.is_server ? 1 : 0

  depends_on = [null_resource.k3s_server]

  # sudo cat needed — node-token is root-only; pi has passwordless sudo
  program = [
    "bash", "-c",
    "SSHPASS='${var.ssh_password}' sshpass -e ssh -o StrictHostKeyChecking=accept-new -o BatchMode=no '${var.ssh_user}@${var.node_ip}' 'python3 -c \"import json,subprocess; print(json.dumps({\\\"token\\\": subprocess.check_output([\\\"sudo\\\",\\\"cat\\\",\\\"/var/lib/rancher/k3s/server/node-token\\\"]).decode().strip()}))\"'"
  ]
}

# Provision an agent (worker) node and join it to the cluster
resource "null_resource" "k3s_agent" {
  count = local.is_server ? 0 : 1

  triggers = {
    node_ip     = var.node_ip
    k3s_version = var.k3s_version
    server_ip   = var.server_ip
  }

  connection {
    type     = "ssh"
    host     = var.node_ip
    user     = var.ssh_user
    password = var.ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      # Write token to a restricted file to avoid exposing it in /proc or ps
      "printf '%s' '${var.server_token}' | sudo tee /var/lib/rancher/k3s-install-token > /dev/null && sudo chmod 600 /var/lib/rancher/k3s-install-token",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' K3S_URL='https://${var.server_ip}:6443' K3S_TOKEN_FILE=/var/lib/rancher/k3s-install-token sh -",
      "sudo rm -f /var/lib/rancher/k3s-install-token",
    ]
  }
}
