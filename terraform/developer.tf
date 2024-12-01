resource "opennebula_virtual_machine" "developer" {

  depends_on = [
    opennebula_virtual_machine.gameserver,
    opennebula_virtual_network_address_range.gameserver
  ]

  template_id = data.opennebula_template.template_developer.id

  name = "ctf-developer"

  cpu    = local.opennebula.limits.developer.cpu
  vcpu   = local.opennebula.limits.developer.vcpu
  memory = local.opennebula.limits.developer.memory

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
    network_id = opennebula_virtual_network.gameserver.id
  }

  disk {
    image_id = data.opennebula_template.template_developer.disk[0].image_id
    target   = "vda"
    size     = local.opennebula.limits.developer.disk
  }
}

resource "null_resource" "hosts_developer" {
  depends_on = [
    opennebula_virtual_machine.developer
  ]

  provisioner "file" {
    connection {
      host         = local.developer.name
      user         = "root"
      private_key  = file("~/.ssh/id_rsa")
      bastion_host = local.haproxy.connection_ip
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }
}

resource "null_resource" "ansible_developer" {
  depends_on = [
    null_resource.hosts_developer,
    local_file.team-private-key-file
  ]

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.developer.name}," \
        --ssh-common-args '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}"' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        --extra-vars "node_ip=${local.developer.private_ip}" \
        --extra-vars "haproxy_ip=${local.haproxy.private_ip}" \
        --extra-vars "teams=${var.nodes}" \
        /ansible/developer-playbook.yml
    EOT
  }
}

locals {
  developer = {
    name          = opennebula_virtual_machine.developer.name
    private_ip    = opennebula_virtual_machine.developer.nic[0].computed_ip
    public_ip     = lookup(local.ip_publica, opennebula_virtual_machine.developer.nic[0].computed_ip, "")
    connection_ip = (local.ansible.connect_to_public_ip ?
      lookup(local.ip_publica, opennebula_virtual_machine.developer.nic[0].computed_ip, "") :
      opennebula_virtual_machine.developer.nic[0].computed_ip)
  }
}

output "developer" {
  value = local.developer
}
