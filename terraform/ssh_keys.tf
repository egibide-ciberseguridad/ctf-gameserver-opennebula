locals {
  ssh_path = "/output/"
}

resource "tls_private_key" "gameserver-tls-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "team-tls-key" {
  count = var.nodes

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "gameserver-private-key-file" {
  file_permission = "600"
  content         = tls_private_key.gameserver-tls-key.private_key_openssh
  filename        = "${local.ssh_path}/gameserver/id_rsa"
}

resource "local_file" "gameserver-public-key-file" {
  file_permission = "600"
  content         = tls_private_key.gameserver-tls-key.public_key_openssh
  filename        = "${local.ssh_path}/gameserver/id_rsa.pub"
}

resource "local_file" "team-private-key-file" {
  # depends_on = [null_resource.output-team-folders]

  count = var.nodes

  file_permission = "600"
  content         = tls_private_key.team-tls-key[count.index].private_key_openssh
  filename        = "${local.ssh_path}/team-${count.index+1}/id_rsa"
}

resource "local_file" "team-public-key-file" {
  # depends_on = [null_resource.output-team-folders]

  count = var.nodes

  file_permission = "600"
  content         = tls_private_key.team-tls-key[count.index].public_key_openssh
  filename        = "${local.ssh_path}/team-${count.index+1}/id_rsa.pub"
}
