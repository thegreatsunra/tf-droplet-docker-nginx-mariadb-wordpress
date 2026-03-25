#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat >&2 <<-EOF
		Usage: $0 --config <path/to/host.yml> [options]

		Deploys themes and additional content from GitHub to each WordPress container,
		and optionally migrates wp-content/uploads/ from a source host.

		Options:
		    --config <path>        Host config file (sets destination host and sites)
		    --from <user@host>     Source host for migrating uploads
		    --from-port <port>     SSH port on source host (default: 22)
		    --from-sudo            Use sudo for docker commands on source host
	EOF
	exit 1
}

CONFIG=""
FROM_HOST=""
FROM_PORT=22
FROM_SUDO=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)    CONFIG="$2"; shift 2 ;;
		--from)      FROM_HOST="$2"; shift 2 ;;
		--from-port) FROM_PORT="$2"; shift 2 ;;
		--from-sudo) FROM_SUDO=true; shift ;;
		*)           echo "Unknown argument: $1" >&2; usage ;;
	esac
done

[[ -z "$CONFIG" ]] && { echo "Error: --config is required" >&2; usage; }

config_abs="$(cd "$(dirname "$CONFIG")" && pwd)/$(basename "$CONFIG")"

TO_USER=$(yq '.user' "$config_abs")
TO_HOST=$(yq '.host' "$config_abs")
TO_PORT=$(yq '.port' "$config_abs")

FROM_DOCKER="docker"
$FROM_SUDO && FROM_DOCKER="sudo docker"

for site_key in $(yq '.sites | keys | .[]' "$config_abs"); do
	container="wp_${site_key}"
	theme_repo=$(yq ".sites.${site_key}.theme_repo // \"\"" "$config_abs")
	additional_repo=$(yq ".sites.${site_key}.additional_content_repo // \"\"" "$config_abs")

	echo "=== ${site_key} ==="

	if [[ -n "$theme_repo" ]]; then
		echo "Deploying theme from ${theme_repo}..."
		ssh -p "$TO_PORT" "${TO_USER}@${TO_HOST}" "
			tmp=\$(mktemp -d)
			trap 'rm -rf \"\$tmp\"' EXIT
			git clone --depth 1 \"${theme_repo}\" \"\$tmp/theme\"
			rm -rf \"\$tmp/theme/.git\"
			docker cp \"\$tmp/theme/.\" ${container}:/var/www/html/wp-content/themes/${site_key}
		"
		echo "Theme deployed."
	fi

	if [[ -n "$additional_repo" ]]; then
		echo "Deploying additional content from ${additional_repo}..."
		ssh -p "$TO_PORT" "${TO_USER}@${TO_HOST}" "
			tmp=\$(mktemp -d)
			trap 'rm -rf \"\$tmp\"' EXIT
			git clone --depth 1 \"${additional_repo}\" \"\$tmp/content\"
			rm -rf \"\$tmp/content/.git\" \"\$tmp/content/.gitignore\"
			docker cp \"\$tmp/content/.\" ${container}:/var/www/html
		"
		echo "Additional content deployed."
	fi

	if [[ -n "$FROM_HOST" ]]; then
		echo "Migrating uploads from ${FROM_HOST}..."
		ssh -p "$FROM_PORT" "$FROM_HOST" \
			"${FROM_DOCKER} exec ${container} tar -cC /var/www/html wp-content/uploads" \
		| ssh -p "$TO_PORT" "${TO_USER}@${TO_HOST}" \
			"docker exec -i ${container} tar -xC /var/www/html"
		echo "Uploads migrated."
	fi

	echo ""
done
