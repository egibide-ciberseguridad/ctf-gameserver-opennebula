resource "cloudflare_record" "domain_name" {
  allow_overwrite = true
  zone_id         = local.cloudflare.zone_id
  name            = local.cloudflare.subdomain
  content         = local.haproxy.public_ip
  type            = "A"
  proxied         = true
}

resource "cloudflare_record" "tunnel_domain_name" {
  allow_overwrite = true
  zone_id         = local.cloudflare.zone_id
  name            = "tunnel-ctf"
  content         = local.haproxy.public_ip
  type            = "A"
  proxied         = false
}
