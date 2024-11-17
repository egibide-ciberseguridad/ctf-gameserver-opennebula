data "opennebula_template" "template" {
  tags = {
    TAG = local.opennebula.vm.tag
  }
}

data "opennebula_virtual_network" "network" {
  name = local.opennebula.vm.network
}

resource "opennebula_virtual_machine" "gameserver" {

  depends_on = [
    opennebula_virtual_machine.haproxy
  ]

  template_id = data.opennebula_template.template.id

  name = "ctf-gameserver"

  cpu    = local.opennebula.limits.gameserver.cpu
  vcpu   = local.opennebula.limits.gameserver.vcpu
  memory = local.opennebula.limits.gameserver.memory

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
    network_id = data.opennebula_virtual_network.network.id
  }

  disk {
    image_id = data.opennebula_template.template.disk[0].image_id
    target   = "vda"
    size     = local.opennebula.limits.gameserver.disk
  }
}

resource "null_resource" "hosts_gameserver" {
  depends_on = [
    opennebula_virtual_machine.gameserver
  ]

  provisioner "file" {
    connection {
      host         = local.gameserver.name
      user         = "root"
      private_key  = file("~/.ssh/id_rsa")
      bastion_host = local.haproxy.connection_ip
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }
}

resource "null_resource" "ansible_gameserver" {
  depends_on = [
    null_resource.hosts_gameserver
  ]

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.gameserver.name}," \
        --ssh-common-args '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}"' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        --extra-vars "node_ip=${local.gameserver.private_ip}" \
        /ansible/common-playbook.yml
    EOT
  }

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.gameserver.name}," \
        --ssh-common-args '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}"' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        --extra-vars "node_ip=${local.gameserver.private_ip}" \
        --extra-vars "haproxy_ip=${local.haproxy.private_ip}" \
        /ansible/gameserver-playbook.yml
    EOT
  }
}

locals {
  gameserver = {
    name          = opennebula_virtual_machine.gameserver.name
    private_ip    = opennebula_virtual_machine.gameserver.nic[0].computed_ip
    public_ip     = lookup(local.ip_publica, opennebula_virtual_machine.gameserver.nic[0].computed_ip, "")
    connection_ip = (local.ansible.connect_to_public_ip ?
      lookup(local.ip_publica, opennebula_virtual_machine.gameserver.nic[0].computed_ip, "") :
      opennebula_virtual_machine.gameserver.nic[0].computed_ip)
  }
}

output "gameserver" {
  value = local.gameserver
}
