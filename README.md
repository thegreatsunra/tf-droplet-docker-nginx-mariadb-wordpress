# DigitalOcean Droplet + WordPress/MariaDB/Nginx in Docker + Certbot TLS + Cloudflare DNS

> Together at last

## Getting started

1. Generate your DigitalOcean and Cloudflare API tokens
1. Create `tf/.env` based on `tf/.env.example` and fill in values
1. Create `tf/dns.json` from `tf/dns.json.example`
1. Create `ansible/sites-available.json` from `ansible/sites-available.json.example`
1. Create `ansible/hosts/<project>/host.yml` based on `ansible/hosts/example/host.yml.example`
1. Create `ansible/playbooks/files/docker.env` based on `ansible/playbooks/files/docker.env.example`

Variables are passed to OpenTofu via `TF_VAR_*` environment variables. The root Taskfile loads `tf/.env` automatically — always use `task` rather than invoking `tofu` directly.

### 1. Provision infrastructure

```shell
task tf:init tf:plan tf:apply
```

cloud-init will upgrade packages, harden SSH (port 4444), and reboot. Wait for it to finish, then confirm SSH is available:

```shell
ssh -p 4444 <username>@<droplet_ip_address>
```

### 2. Provision the server

```shell
bash ansible/run-playbook.bash --config ansible/hosts/<project>/host.yml
```

Ansible will install packages, configure UFW, set up the user environment (zsh, Oh My Zsh, Atuin), install Docker, and deploy the WordPress stack.

### 3. Enable SSL

SSH in and issue staging certs first to verify the webroot challenge works:

```shell
ssh -p 4444 <username>@<droplet_ip_address>
bash ~/stuff/issue-certs.bash
```

If staging succeeds, issue real certs:

```shell
bash ~/stuff/issue-certs.bash --production
```

Then uncomment the HTTPS server block in `~/stuff/docker/nginx/conf.d/default.conf` and restart nginx:

```shell
cd ~/stuff/docker && sudo docker compose restart nginx
```

Certbot renewal runs automatically every 12 hours via the certbot container.

## Maintenance

```shell
## Force-recreate your deployed Docker containers
cd ~/stuff/docker && sudo docker compose up -d --force-recreate
```

## Destroying what you've made

```shell
task tf:destroy
```

## License

The MIT License (MIT)

Copyright (c) 2022-2026 Dane Petersen
