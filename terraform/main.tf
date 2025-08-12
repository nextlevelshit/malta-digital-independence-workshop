terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.48"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "~> 2.2"
    }
  }
}

locals {
  domain = var.domain
  participants = [
    "hopper", "curie", "lovelace", "noether", "hamilton",
    "franklin", "johnson", "clarke", "goldberg", "liskov",
    "wing", "rosen", "shaw", "karp", "rich"
  ]
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken = var.hetzner_dns_token
}

resource "hcloud_ssh_key" "workshop" {
  name       = "code-crispies-workshop"
  public_key = var.ssh_public_key
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
    domain          = local.domain
    ssh_public_key  = var.ssh_public_key
  })
  
  labels = {
    project = "code-crispies-workshop"
    participant = each.key
  }
}

resource "hetznerdns_record" "participant_main" {
  for_each = toset(local.participants)
  
  zone_id = var.dns_zone_id
  name    = each.key
  type    = "A" 
  value   = hcloud_server.participant[each.key].ipv4_address
  ttl     = 60
}

resource "hetznerdns_record" "participant_wildcard" {
  for_each = toset(local.participants)
  
  zone_id = var.dns_zone_id
  name    = "*.${each.key}"
  type    = "A"
  value   = hcloud_server.participant[each.key].ipv4_address
  ttl     = 60
}

output "participant_ips" {
  value = {
    for name, server in hcloud_server.participant : name => server.ipv4_address
  }
  description = "IP addresses of participant servers"
}

output "participant_urls" {
  value = {
    for name, server in hcloud_server.participant : name => "https://traefik.${name}.${local.domain}"
  }
  description = "Traefik URLs for each participant"
}
