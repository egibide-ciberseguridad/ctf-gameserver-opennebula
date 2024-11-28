locals {
  hosts = join("\n", [
    "127.0.0.1 localhost localhost.localdomain",
    join(" ", [local.gameserver.private_ip, opennebula_virtual_machine.gameserver.name]),
    join("\n", flatten([
      for i in opennebula_virtual_machine.nodes[*] : join(" ", [i.nic[0].computed_ip, i.name])
    ])),
    join("\n", flatten([
      for i in opennebula_virtual_machine.subs[*] : join(" ", [i.nic[0].computed_ip, i.name])
    ])),
    join(" ", [local.haproxy.private_ip, opennebula_virtual_machine.haproxy.name]),
    ""
  ])
  cluster_ips = join(",", [
    local.gameserver.private_ip,
    join(",", flatten([
      for i in opennebula_virtual_machine.nodes[*] : i.nic[0].computed_ip
    ])),
  ])
}

output "hosts" {
  value = local.hosts
}

output "cluster_ips" {
  value = local.cluster_ips
}

resource "local_file" "workspace_hosts" {
  filename = "/etc/hosts"
  content  = local.hosts
}
