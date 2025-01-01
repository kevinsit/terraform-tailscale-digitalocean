variable "digitalocean_token" {
  description = "DigitalOcean API Token."
  type        = string
}

variable "digitalocean_location" {
  description = "DigitalOcean Server Location."
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale Auth Key."
  type        = string
}

variable "ssh_public_key_file" {
  description = "SSH public key containing the SSH key to be added to the droplet."
  type        = string
}

variable "ssh_private_key_file" {
  description = "SSH private key to authentiate against the droplet."
  type        = string
}

variable "droplet_size" {
  description = "The Tailscale droplet size."
  type        = string
}

variable "droplet_image" {
  description = "The Tailscale droplet based image."
  type        = string
}