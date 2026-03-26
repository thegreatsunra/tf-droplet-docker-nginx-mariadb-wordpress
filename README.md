# DigitalOcean Droplet + WordPress/MariaDB/Nginx in Docker + Certbot TLS + Cloudflare DNS

> Together at last

## Getting started

1. Generate your DigitalOcean and Cloudflare API tokens
1. Create `tf/.env` from `tf/.env.example` and fill in values
1. Create `tf/dns.json` from `tf/dns.json.example`
1. Create `hosts/<hostname>.yml` from `hosts/hostname.yml.example`
1. Create `ansible/playbooks/files/docker.env` from `ansible/playbooks/files/docker.env.example`

Variables are passed to OpenTofu via `TF_VAR_*` environment variables. The root Taskfile loads `tf/.env` automatically — always use `task` rather than invoking `tofu` directly.

### 1. Provision infrastructure

```shell
task tf:init tf:plan tf:apply
```

Once apply completes, add the new droplet IP to `hosts/<hostname>.yml`.

cloud-init will upgrade packages, harden SSH (port 4444), and reboot. Wait for it to finish, then confirm SSH is available:

```shell
ssh -p 4444 <username>@<droplet_ip_address>
```

### 2. Provision the server

```shell
ansible/run-playbook.bash --config hosts/<hostname>.yml
```

Ansible will install packages, configure UFW, set up the user environment (zsh, Oh My Zsh, Atuin), install Docker, and deploy the WordPress stack. The stack starts automatically with self-signed placeholder certs.

### 3. Enable SSL

SSH in and issue staging certs first to verify the ACME challenge works:

```shell
ssh -p 4444 <username>@<droplet_ip_address>
~/stuff/issue-certs.bash
```

If staging succeeds, issue real certs:

```shell
~/stuff/issue-certs.bash --production
```

Certbot renewal runs automatically every 12 hours via the certbot container.

### 4. Migrate from an existing host (optional)

```shell
scripts/migrate-databases.bash --config hosts/<hostname>.yml --from <user@old-host> --from-port <port> [--from-sudo]
scripts/migrate-wordpress.bash --config hosts/<hostname>.yml --from <user@old-host> --from-port <port> [--from-sudo]
```

Pass `--from-sudo` if Docker commands on the source host require sudo.

`migrate-databases.bash` dumps and restores each MariaDB database. `migrate-wordpress.bash` deploys themes and additional content from GitHub, then migrates `wp-content/uploads/` and any `webroot_dirs` defined in the host config via tar pipe between hosts.

## Maintenance

```shell
## Force-recreate your deployed Docker containers
cd ~/stuff/docker && docker compose up -d --force-recreate
```

## Destroying what you've made

```shell
task tf:destroy
```

## License

The MIT License (MIT)

Copyright (c) 2022-2026 Dane Petersen
