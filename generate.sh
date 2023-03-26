#!/usr/bin/env bash

set -euo pipefail

cf_ips="$(mktemp)"
cf_ip_config="${cf_ip_config:-/etc/nginx/conf.d/cloudflare-set-real-ip.conf}"
trap 'rm -f "$cf_ips"' EXIT

for cmd in curl sed mv chmod rm cmp; do
    command -v "$cmd" >/dev/null || { echo >&2 "Error: $cmd not found. Please make sure it's installed and try again."; exit 1; }
done

if [ "${1:-}" = "--cron" ]; then
    sleep $((RANDOM % 900))
fi

chmod 644 "$cf_ips"

for file in ips-v4 ips-v6; do
    curl --compressed -sLo- "https://www.cloudflare.com/$file" >> "$cf_ips"
    echo '' >> "$cf_ips"
done

sed -i -e 's/^/set_real_ip_from /g' -e 's/$/;/g' -e '1i real_ip_header CF-Connecting-IP;' "$cf_ips"

if ! [ -e "$cf_ip_config" ]; then
    mv -f "$cf_ips" "$cf_ip_config"
    echo "nginx config added."
elif cmp -s "$cf_ips" "$cf_ip_config"; then
    echo "No changes detected."
    rm -f "$cf_ips"
else
    mv -f "$cf_ips" "$cf_ip_config"
    echo "nginx config updated."
fi
