variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "hetzner_dns_token" {
  description = "Hetzner DNS API token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "dns_zone_id" {
  description = "Hetzner DNS Zone ID"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Workshop domain"
  type        = string
  default     = "codecrispi.es"
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}
