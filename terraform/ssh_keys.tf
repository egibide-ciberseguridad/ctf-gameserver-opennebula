locals {
  ssh_path = "/keys/"
}

resource "tls_private_key" "team-tls-key" {
  count = var.nodes

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "team-private-key-file" {
  count = var.nodes

  file_permission = "600"
  content         = tls_private_key.team-tls-key[count.index].private_key_openssh
  filename        = "${local.ssh_path}/${count.index+1}/id_rsa"
}

resource "local_file" "team-public-key-file" {
  count = var.nodes

  file_permission = "600"
  content         = tls_private_key.team-tls-key[count.index].public_key_openssh
  filename        = "${local.ssh_path}/${count.index+1}/id_rsa.pub"
}
