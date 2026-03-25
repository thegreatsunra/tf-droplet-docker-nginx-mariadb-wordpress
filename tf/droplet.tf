resource "digitalocean_droplet" "droplet" {
  backups    = var.droplet_backups
  image      = var.droplet_image
  monitoring = true
  name       = var.droplet_hostname
  region     = var.droplet_region
  size       = var.droplet_size
  tags       = var.resource_tags
  user_data  = templatefile("./user_data/user_data.yml.tftpl", local.user_data_vars)
}
