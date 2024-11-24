data "opennebula_templates" "search" {
  name_regex = ".*"
  tags = {
    TAG = local.opennebula.vm.tag
  }
  sort_on = "register_date"
  order   = "ASC" # La más reciente
}

data "opennebula_template" "template" {
  id = data.opennebula_templates.search.templates[0].id
}

data "opennebula_virtual_network" "network" {
  name = local.opennebula.vm.network
}
