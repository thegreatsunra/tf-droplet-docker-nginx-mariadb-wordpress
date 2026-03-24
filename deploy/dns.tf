## each.key is the full domain name, with subdomain if applicable
## each.value is the zone, without zubdomain
## this way the keys are always unique, even if they share the same domain
data "cloudflare_zone" "zone" {
  for_each = local.container_loop.dns

  name = each.value
}

resource "cloudflare_record" "record" {
  for_each = local.container_loop.dns

  name    = each.key
  proxied = var.cloudflare_record_proxied
  type    = "A"
  content = digitalocean_droplet.droplet.ipv4_address
  zone_id = data.cloudflare_zone.zone[each.key].id
}
