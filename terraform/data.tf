data "opennebula_templates" "search" {
  name_regex = local.opennebula.vm.name
  sort_on    = "register_date"
  order      = "ASC" # La más reciente
}

data "opennebula_template" "template" {
  id = data.opennebula_templates.search.templates[0].id
}

data "opennebula_templates" "search_developer" {
  name_regex = local.opennebula.vm.name_desktop
  sort_on    = "register_date"
  order      = "ASC" # La más reciente
}

data "opennebula_template" "template_developer" {
  id = data.opennebula_templates.search_developer.templates[0].id
}
