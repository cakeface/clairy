terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

data "digitalocean_ssh_key" "clairy" {
  name = "clairy-mac"
}

data "digitalocean_domain" "ckfce" {
  name = "ckfce.com"
}

resource "digitalocean_droplet" "clairy" {
  image    = "ubuntu-24-04-x64"
  name     = "clairy"
  region   = "nyc3"
  size     = "s-4vcpu-16gb-amd"
  ssh_keys = [data.digitalocean_ssh_key.clairy.id]

  monitoring = true
  backups    = true

  tags = ["agent", "experimentation"]
}

resource "digitalocean_record" "clairy" {
  domain = data.digitalocean_domain.ckfce.id
  type   = "A"
  name   = "clairy"
  value  = digitalocean_droplet.clairy.ipv4_address
  ttl    = 1800
}

output "droplet_ip" {
  value = digitalocean_droplet.clairy.ipv4_address
}

output "droplet_id" {
  value = digitalocean_droplet.clairy.id
}

output "subdomain" {
  value = "clairy.ckfce.com"
}
