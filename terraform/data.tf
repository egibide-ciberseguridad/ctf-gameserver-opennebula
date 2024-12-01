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

data "opennebula_templates" "search_developer" {
  name_regex = ".*"
  tags = {
    TAG = local.opennebula.vm.tag_desktop
  }
  sort_on = "register_date"
  order   = "ASC" # La más reciente
}

data "opennebula_template" "template_developer" {
  id = data.opennebula_templates.search_developer.templates[0].id
}
