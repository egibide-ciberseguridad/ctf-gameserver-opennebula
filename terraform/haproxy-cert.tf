resource "tls_private_key" "haproxy-tls-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "haproxy-cert" {
  private_key_pem = tls_private_key.haproxy-tls-key.private_key_pem

  subject {
    common_name  = "ctf.local"
    organization = "Egibide"
  }

  validity_period_hours = 24*365*5

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_file" "haproxy-cert-file" {
  content = format("%s\n%s", tls_self_signed_cert.haproxy-cert.cert_pem, tls_private_key.haproxy-tls-key.private_key_pem)
  filename = "/certs/haproxy/server.pem"
}
