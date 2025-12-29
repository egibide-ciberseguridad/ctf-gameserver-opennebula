resource "opennebula_virtual_machine" "haproxy" {

  depends_on = [
    opennebula_virtual_network_address_range.public
  ]

  template_id = data.opennebula_template.template.id

  name = "ctf-haproxy"

  cpu    = local.opennebula.limits.haproxy.cpu
  vcpu   = local.opennebula.limits.haproxy.vcpu
  memory = local.opennebula.limits.haproxy.memory

  lock = local.opennebula.vm.locked ? "USE" : "UNLOCK"

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = join("\n", [
      join("\n", split("|", replace(var.SSH_PUBLIC_KEY, "/[\"']/", ""))),
      file("~/.ssh/id_rsa.pub")
    ])
  }

  nic {
    model      = "virtio"
    network_id = opennebula_virtual_network.public.id
  }

  disk {
    image_id = data.opennebula_template.template.disk[0].image_id
    target   = "vda"
    size     = local.opennebula.limits.haproxy.disk
  }
}

resource "terraform_data" "hosts_haproxy" {
  depends_on = [
    opennebula_virtual_machine.haproxy
  ]

  provisioner "file" {
    connection {
      host        = local.haproxy.connection_ip
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }
}

resource "terraform_data" "config_haproxy" {
  depends_on = [
    opennebula_virtual_machine.haproxy
  ]

  provisioner "file" {
    connection {
      host = local.haproxy.connection_ip
      user = "root"
      private_key = file("~/.ssh/id_rsa")
    }

    content = templatefile("${path.module}/haproxy.tftpl", {
      haproxy    = local.haproxy,
      gameserver = local.gameserver,
    })
    destination = "/var/tmp/haproxy.cfg"
  }
}

resource "terraform_data" "ansible_haproxy" {
  depends_on = [
    terraform_data.hosts_haproxy,
    terraform_data.config_haproxy,
    local_file.haproxy-cert-file,
  ]

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.haproxy.connection_ip}," \
        --extra-vars "node_ip=${local.haproxy.private_ip}" \
        --extra-vars "{ "ips" : [${local.cluster_ips}]}" \
        /ansible/haproxy-playbook.yml
    EOT
  }
}

resource "terraform_data" "ansible_ssh_tunnel" {
  depends_on = [
    terraform_data.ansible_gameserver,
  ]

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.haproxy.connection_ip}," \
        --extra-vars "node_ip=${local.haproxy.private_ip}" \
        --extra-vars "teams=${var.nodes}" \
        /ansible/ssh-tunnel-playbook.yml
    EOT
  }
}

locals {
  haproxy = {
    name          = opennebula_virtual_machine.haproxy.name
    private_ip    = opennebula_virtual_machine.haproxy.nic[0].computed_ip
    public_ip     = lookup(local.ip_publica, opennebula_virtual_machine.haproxy.nic[0].computed_ip, "")
    connection_ip = (local.ansible.connect_to_public_ip ?
      lookup(local.ip_publica, opennebula_virtual_machine.haproxy.nic[0].computed_ip, "") :
      opennebula_virtual_machine.haproxy.nic[0].computed_ip)
  }
}

output "haproxy" {
  value = local.haproxy
}
