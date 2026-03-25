variable "cloudflare_record_proxied" {
  type    = bool
  default = false
}

variable "cloudflare_token" {
  type = string
}

variable "digital_ocean_token" {
  type = string
}

variable "droplet_backups" {
  type    = bool
  default = true
}

variable "droplet_hostname" {
  type = string
  validation {
    condition     = length(regexall("[^-.a-z]+", var.droplet_hostname)) == 0
    error_message = "Droplet hostname can only contain the following characters: a-z, -, ."
  }
}

variable "droplet_image" {
  type    = string
  default = "ubuntu-24-04-x64"
}

variable "droplet_region" {
  type    = string
  default = "nyc1"
}

variable "droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}

variable "email_address" {
  type = string
}

variable "project" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "resource_tags" {
  type    = list(string)
  default = ["droplet"]
}

variable "user_full_name" {
  type = string
}

variable "username" {
  type = string
}
