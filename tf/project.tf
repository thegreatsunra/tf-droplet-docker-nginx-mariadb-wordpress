data "digitalocean_project" "project" {
  name = var.project
}

resource "digitalocean_project_resources" "project-resources" {
  project = data.digitalocean_project.project.id
  resources = [
    digitalocean_droplet.droplet.urn
  ]
}
