locals {

  dns = jsondecode(file("./dns.json"))

  sites_available = jsondecode(file("./sites-available.json"))

  container_loop = {
    database_prefix  = "db_"
    dns              = local.dns
    email_address    = var.email_address
    sites_available  = local.sites_available
    wordpress_prefix = "wp_"
  }

  user_data_vars = {
    public_ssh_key = var.public_ssh_key
    user_full_name = var.user_full_name
    username       = var.username
  }
}
