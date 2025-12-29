resource "cloudflare_dns_record" "domain_name" {
  zone_id = local.cloudflare.zone_id
  name    = local.cloudflare.subdomain
  content = local.haproxy.public_ip
  type    = "A"
  proxied = true
  ttl     = 1 # auto
}

resource "cloudflare_dns_record" "tunnel_domain_name" {
  zone_id = local.cloudflare.zone_id
  name    = "tunnel-ctf"
  content = local.haproxy.public_ip
  type    = "A"
  proxied = false
  ttl     = 1 # auto
}
