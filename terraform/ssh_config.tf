resource "local_file" "ssh_config" {
  filename = "/root/.ssh/config"
  content = templatefile("${path.module}/ssh_config.tftpl", {
    connection_ip = local.haproxy.connection_ip,
    items = concat(local.nodes, local.subs)
  })
}
