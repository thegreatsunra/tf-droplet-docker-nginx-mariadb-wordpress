#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

usage() {
	cat >&2 <<-EOF
		Usage: $0 --from <user@host> --to <user@host> [options]

		Options:
		    --from <user@host>    Source host
		    --to <user@host>      Destination host
		    --from-port <port>    SSH port on source host (default: 22)
		    --to-port <port>      SSH port on destination host (default: 22)
		    --from-sudo           Use sudo for docker commands on source host
	EOF
	exit 1
}

FROM_HOST=""
TO_HOST=""
FROM_PORT=22
TO_PORT=22
FROM_SUDO=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--from)      FROM_HOST="$2"; shift 2 ;;
		--to)        TO_HOST="$2"; shift 2 ;;
		--from-port) FROM_PORT="$2"; shift 2 ;;
		--to-port)   TO_PORT="$2"; shift 2 ;;
		--from-sudo) FROM_SUDO=true; shift ;;
		*)           echo "Unknown argument: $1" >&2; usage ;;
	esac
done

[[ -z "$FROM_HOST" ]] && { echo "Error: --from is required" >&2; usage; }
[[ -z "$TO_HOST" ]] && { echo "Error: --to is required" >&2; usage; }

SITES_FILE="sites-available.json"
[[ ! -f "$SITES_FILE" ]] && { echo "Error: $SITES_FILE not found" >&2; exit 1; }

FROM_DOCKER="docker"
$FROM_SUDO && FROM_DOCKER="sudo docker"

for site_key in $(jq -r 'keys[]' "$SITES_FILE"); do
	db="wp_db_${site_key}"
	echo "--- $db ---"

	from_count=$(ssh -p "$FROM_PORT" "$FROM_HOST" \
		"${FROM_DOCKER} exec mariadb mariadb -uroot -p\"\$(${FROM_DOCKER} exec mariadb printenv MYSQL_ROOT_PASSWORD)\" \
		--skip-column-names -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${db}';\" 2>/dev/null")

	if [[ "${from_count:-0}" -eq 0 ]]; then
		echo "Warning: no tables found in $db on source host, skipping." >&2
		continue
	fi

	echo "Dumping $from_count tables from source..."
	ssh -p "$FROM_PORT" "$FROM_HOST" \
		"${FROM_DOCKER} exec mariadb mariadb-dump -uroot -p\"\$(${FROM_DOCKER} exec mariadb printenv MYSQL_ROOT_PASSWORD)\" ${db}" \
	| ssh -p "$TO_PORT" "$TO_HOST" \
		"PW=\$(docker exec mariadb printenv MYSQL_ROOT_PASSWORD) && docker exec -i mariadb mariadb -uroot -p\"\$PW\" ${db}"

	to_count=$(ssh -p "$TO_PORT" "$TO_HOST" \
		"PW=\$(docker exec mariadb printenv MYSQL_ROOT_PASSWORD) && docker exec mariadb mariadb -uroot -p\"\$PW\" \
		--skip-column-names -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${db}';\" 2>/dev/null")

	echo "Imported: $to_count tables."
done
