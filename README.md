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

cloud-init will upgrade packages, install dependencies, harden SSH (port 4444), and configure UFW. Wait for it to finish and the droplet to reboot, then confirm SSH is available:

```shell
ssh -p 4444 <username>@<droplet_ip_address>
```

### 2. Provision the server

```shell
bash ansible/run-playbook.bash --config ansible/hosts/<project>/host.yml
```

Ansible will install Docker and deploy the WordPress stack.

### 3. Enable SSL

Once the stack is running, SSH in and check certbot validated your domain:

```shell
ssh -p 4444 <username>@<droplet_ip_address>
cd ~/stuff/docker

## check certbot created a cert folder for your domain
sudo docker compose exec nginx ls -la /etc/letsencrypt/live

## re-run certbot with --force-renewal to get real certs
sudo docker compose up --force-recreate -d --no-deps certbot

## then comment out the HTTP block and un-comment the HTTPS block in nginx default.conf
## then restart containers
sudo docker compose restart
```

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
