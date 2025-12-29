resource "opennebula_virtual_network" "public" {
  name   = "ctf-public"
  type   = "bridge"
  bridge = "aulas"
  mtu    = 1500

  gateway      = "172.20.1.2"
  dns          = "192.168.10.1 1.1.1.1"
  network_mask = "255.255.0.0"

  security_groups = [0]
}

resource "opennebula_virtual_network_address_range" "public" {
  virtual_network_id = opennebula_virtual_network.public.id
  ar_type            = "IP4"
  size               = local.opennebula.public_network_size
  ip4                = local.opennebula.public_network_ip
}

resource "opennebula_virtual_network" "gameserver" {
  name   = "ctf-gameserver"
  type   = "bridge"
  bridge = "aulas"
  mtu    = 1500

  gateway      = "172.20.1.2"
  dns          = "192.168.10.1 1.1.1.1"
  network_mask = "255.255.0.0"

  security_groups = [0]
}

resource "opennebula_virtual_network_address_range" "gameserver" {
  virtual_network_id = opennebula_virtual_network.gameserver.id
  ar_type            = "IP4"
  size               = 10
  ip4                = "${local.opennebula.network_prefix}.1"
}

resource "opennebula_virtual_network" "teams" {
  count = var.nodes

  name   = "ctf-team-${count.index + 1}"
  type   = "bridge"
  bridge = "aulas"
  mtu    = 1500

  gateway      = "172.20.1.2"
  dns          = "192.168.10.1 1.1.1.1"
  network_mask = "255.255.0.0"

  security_groups = [0]
}

resource "opennebula_virtual_network_address_range" "teams" {
  count = var.nodes

  virtual_network_id = opennebula_virtual_network.teams[count.index].id
  ar_type            = "IP4"
  size               = 10
  ip4                = "${local.opennebula.network_prefix}.${10 * (count.index + 1)}"
}
