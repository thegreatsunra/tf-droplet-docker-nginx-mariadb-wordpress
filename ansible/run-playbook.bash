#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

usage() {
	echo "Usage: $0 --config <path/to/host.yml>" >&2
	exit 1
}

while [[ $# -gt 0 ]]; do
	case $1 in
		--config)
			config="$2"
			shift 2
			;;
		*)
			echo "Unknown argument: $1" >&2
			usage
			;;
	esac
done

if [[ -z "${config:-}" ]]; then
	usage
fi

host=$(yq '.host' "$config")
port=$(yq '.port' "$config")
user=$(yq '.user' "$config")
playbook=$(yq '.playbook' "$config")

tmp_vars=$(mktemp)
trap 'rm -f "$tmp_vars"' EXIT

yq '.vars // {}' "$config" > "$tmp_vars"

ansible-playbook \
	--inventory "${host}:${port}," \
	--user "$user" \
	--extra-vars "@${tmp_vars}" \
	"playbooks/${playbook}"
