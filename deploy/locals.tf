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
    docker_compose_base64                        = base64encode(templatefile("./docker/docker-compose.yml.tftpl", local.container_loop))
    droplet_hostname                             = var.droplet_hostname
    nginx_conf_base64                            = base64encode(templatefile("./docker/nginx/conf.d/default.conf.tftpl", local.container_loop))
    nginx_config_general_conf_base64             = base64encode(file("./docker/nginx/conf.d/modules/general.conf"))
    nginx_config_php_conf_base64                 = base64encode(templatefile("./docker/nginx/conf.d/modules/php.conf.tftpl", local.container_loop))
    nginx_config_security_conf_base64            = base64encode(file("./docker/nginx/conf.d/modules/security.conf"))
    nginx_config_wordpress_conf_base64           = base64encode(file("./docker/nginx/conf.d/modules/wordpress.conf"))
    nginx_config_wordpress_multisite_conf_base64 = base64encode(file("./docker/nginx/conf.d/modules/wordpress-multisite.conf"))
    public_ssh_key                               = var.public_ssh_key
    root_temporary_password                      = var.root_temporary_password
    tmp_folder_path                              = var.tmp_folder_path
    user_full_name                               = var.user_full_name
    user_temporary_password                      = var.user_temporary_password
    username                                     = var.username
    wordpress_dotenv_base64                      = base64encode(file("./docker/.env"))
  }
}
