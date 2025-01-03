terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_ssh_key" "default" {
  name       = "SSH public key"
  public_key = file(var.ssh_public_key_file)
}

resource "random_id" "random_suffix" {
  keepers = {
    digitalocean_location = var.digitalocean_location
    droplet_size = var.droplet_size
    droplet_image = var.droplet_image
  }

  byte_length = 8
}

resource "digitalocean_project" "tailscale" {
  name        = "tailscale-exit-node-${random_id.random_suffix.hex}"
  description = "Tailscale Exit Node ${random_id.random_suffix.hex}"
  resources   = [
    digitalocean_droplet.tailscale_exit_node.urn
  ]
}

resource "digitalocean_droplet" "tailscale_exit_node" {
  name      = "tailscale-exit-node-${random_id.random_suffix.hex}"
  size      = var.droplet_size
  image     = var.droplet_image
  region    = var.digitalocean_location
  ssh_keys  = [ digitalocean_ssh_key.default.fingerprint ]
  tags      = [ "tailscale" ]
  user_data = <<EOF
  #cloud-config
  runcmd:
    - apt-get update
    - apt-get install -y curl
    - curl -fsSL https://tailscale.com/install.sh | sh
    - echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    - echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    - sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
    - tailscale up --authkey=${var.tailscale_auth_key} --advertise-exit-node
  EOF
}

# This is a failsafe mechanism to remove the node from tailscale when it is destroyed.
# If the tailscale API auth key is already marked as ephemeral, then this extra step
# should not be necessary.
resource "terraform_data" "tailscale_exit_node_logoff" {
  triggers_replace = {
    ipv4_address = digitalocean_droplet.tailscale_exit_node.ipv4_address
    ssh_private_key = file(var.ssh_private_key_file)
  }
  
  provisioner "remote-exec" {
    when    = destroy

    inline  = [
      "echo 'Running extra step before destroying the server...'",
      "tailscale logout",
      "echo 'Tailscale logged out'",
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = self.triggers_replace.ssh_private_key
      host        = self.triggers_replace.ipv4_address
    }
  }
}

resource "digitalocean_firewall" "tailscale_exit_node_firewall" {
  name = "tailscale-exit-node-${random_id.random_suffix.hex}"

  droplet_ids = [ digitalocean_droplet.tailscale_exit_node.id ]

  inbound_rule {
    protocol         = "udp"
    port_range       = "41641"
    source_addresses = [ "0.0.0.0/0", "::/0" ]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "22"
    source_addresses = [ "0.0.0.0/0", "::/0" ]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [ "0.0.0.0/0", "::/0" ]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = [ "0.0.0.0/0", "::/0" ]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = [ "0.0.0.0/0", "::/0" ]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = [ "0.0.0.0/0", "::/0" ]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = [ "0.0.0.0/0", "::/0" ]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "3478"
    destination_addresses = [ "0.0.0.0/0", "::/0" ]
  }
}