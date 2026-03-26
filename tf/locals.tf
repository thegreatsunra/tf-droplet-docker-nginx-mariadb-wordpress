locals {

  dns = jsondecode(file("./dns.json"))
  droplet_hostname_zone = length(split(".", var.droplet_hostname)) > 2 ? join(".", slice(split(".", var.droplet_hostname), 1, length(split(".", var.droplet_hostname)))) : var.droplet_hostname

  user_data_vars = {
    droplet_hostname = var.droplet_hostname
    public_ssh_key   = var.public_ssh_key
    timezone         = var.timezone
    user_full_name   = var.user_full_name
    username         = var.username
  }
}
