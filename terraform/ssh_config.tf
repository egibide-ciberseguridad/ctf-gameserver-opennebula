resource "local_file" "ssh_config" {
  filename = "/root/.ssh/config"
  content = templatefile("${path.module}/ssh_config.tftpl", {
    haproxy      = local.haproxy,
    gameserver   = local.gameserver,
    is_public_ip = local.ansible.connect_to_public_ip,
    items = concat(local.nodes, local.subs),
  })
}
