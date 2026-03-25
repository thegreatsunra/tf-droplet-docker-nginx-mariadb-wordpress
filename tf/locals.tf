locals {

  dns = jsondecode(file("./dns.json"))

  user_data_vars = {
    droplet_hostname = var.droplet_hostname
    public_ssh_key   = var.public_ssh_key
    timezone         = var.timezone
    user_full_name   = var.user_full_name
    username         = var.username
  }
}
