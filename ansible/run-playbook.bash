#!/usr/bin/env bash
set -euo pipefail

usage() {
	echo "Usage: $0 --config <path/to/host.yml>" >&2
	exit 1
}

config=""
while [[ $# -gt 0 ]]; do
	case $1 in
		--config) config="$2"; shift 2 ;;
		*)        echo "Unknown argument: $1" >&2; usage ;;
	esac
done

[[ -z "$config" ]] && usage

config_dir="$(cd "$(dirname "$config")" && pwd)"
config_abs="${config_dir}/$(basename "$config")"

host=$(yq '.host' "$config_abs")
port=$(yq '.port' "$config_abs")
user=$(yq '.user' "$config_abs")
playbook=$(yq '.playbook' "$config_abs")

tmp_vars=$(mktemp)
trap 'rm -f "$tmp_vars"' EXIT

yq '.vars // {}' "$config_abs" > "$tmp_vars"

ansible_dir="$(cd "$(dirname "$0")" && pwd)"

ansible-playbook \
	--inventory "${host}:${port}," \
	--user "$user" \
	--extra-vars "@${tmp_vars}" \
	--extra-vars "host_config_file=${config_abs}" \
	"${ansible_dir}/playbooks/${playbook}"
