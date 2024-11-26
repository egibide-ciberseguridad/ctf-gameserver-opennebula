resource "opennebula_virtual_machine" "subs" {

  depends_on = [
    opennebula_virtual_machine.gameserver,
    opennebula_virtual_network_address_range.teams
  ]

  count = var.nodes

  template_id = data.opennebula_template.template.id

  name = "ctf-sub-${count.index+1}"

  cpu    = local.opennebula.limits.subs.cpu
  vcpu   = local.opennebula.limits.subs.vcpu
  memory = local.opennebula.limits.subs.memory

  lock = local.opennebula.vm.locked ? "USE" : "UNLOCK"

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = join("\n", [
      join("\n", split("|", replace(var.SSH_PUBLIC_KEY, "/[\"']/", ""))),
      file("~/.ssh/id_rsa.pub")
    ])
  }

  group = local.opennebula.connection.group

  nic {
    model      = "virtio"
    network_id = opennebula_virtual_network.teams[count.index].id
  }

  disk {
    image_id = data.opennebula_template.template.disk[0].image_id
    target   = "vda"
    size     = local.opennebula.limits.subs.disk
  }
}

resource "null_resource" "hosts_subs" {
  depends_on = [
    opennebula_virtual_machine.subs
  ]

  count = var.nodes

  provisioner "file" {
    connection {
      host         = local.subs[count.index].name
      user         = "root"
      private_key  = file("~/.ssh/id_rsa")
      bastion_host = local.haproxy.connection_ip
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }
}

resource "null_resource" "ansible_subs" {
  depends_on = [
    null_resource.hosts_subs,
    local_file.team-public-key-file
  ]

  count = var.nodes

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.subs[count.index].name}," \
        --ssh-common-args '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}"' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        --extra-vars "team_id=${count.index+1}" \
        /ansible/sub-playbook.yml
    EOT
  }
}

locals {
  subs = [
    for node in opennebula_virtual_machine.subs[*] :
    {
      name          = node.name
      private_ip    = node.nic[0].computed_ip
      public_ip     = lookup(local.ip_publica, node.nic[0].computed_ip, "")
      connection_ip = (local.ansible.connect_to_public_ip ?
        lookup(local.ip_publica, node.nic[0].computed_ip, "") :
        node.nic[0].computed_ip)
    }
  ]
}

output "subs" {
  value = local.subs
}
