locals {
  domain = "codecrispi.es"
  participants = [
    "hopper", "curie", "lovelace", "noether", "hamilton",
    "franklin", "johnson", "clarke", "goldberg", "liskov",
    "wing", "rosen", "shaw", "karp", "rich"
  ]
}

resource "hcloud_server" "participant" {
  for_each = toset(local.participants)
  
  name        = each.key
  image       = "ubuntu-22.04"
  server_type = "cx21"
  location    = "nbg1"
  
  ssh_keys = [hcloud_ssh_key.workshop.id]
  
  user_data = templatefile("${path.module}/cloud-init.yml", {
    participant_name = each.key
    domain = local.domain
  })
}

resource "hcloud_dns_record" "participant_main" {
  for_each = toset(local.participants)
  
  zone_id = var.dns_zone_id
  name    = each.key
  type    = "A" 
  value   = hcloud_server.participant[each.key].ipv4_address
  ttl     = 60
}

resource "hcloud_dns_record" "participant_wildcard" {
  for_each = toset(local.participants)
  
  zone_id = var.dns_zone_id
  name    = "*.${each.key}"
  type    = "A"
  value   = hcloud_server.participant[each.key].ipv4_address
  ttl     = 60
}
