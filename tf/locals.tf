locals {

  # Derives the Cloudflare zone from a domain by stripping the leading subdomain
  # if present (>2 labels → strip first label), otherwise using the domain as-is.
  # e.g. "sub.example.com" → "example.com", "example.com" → "example.com"
  # Limitation: assumes single-label TLDs. Breaks for apex domains on multi-label
  # TLDs — "example.co.uk" has 3 labels, so it's incorrectly treated as a subdomain
  # and stripped to "co.uk" instead of being used as-is.
  dns = {
    for domain in yamldecode(file("./dns.yml")).sites :
    domain => length(split(".", domain)) > 2 ? join(".", slice(split(".", domain), 1, length(split(".", domain)))) : domain
  }

  droplet_hostname_zone = length(split(".", var.droplet_hostname)) > 2 ? join(".", slice(split(".", var.droplet_hostname), 1, length(split(".", var.droplet_hostname)))) : var.droplet_hostname

  user_data_vars = {
    droplet_hostname = var.droplet_hostname
    public_ssh_key   = var.public_ssh_key
    timezone         = var.timezone
    user_full_name   = var.user_full_name
    username         = var.username
  }
}
