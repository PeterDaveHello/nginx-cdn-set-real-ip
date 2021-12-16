#!/usr/bin/env bash

set -e

cf_ips="$(mktemp)"
cf_ip_config="${cf_ip_config:-/etc/nginx/conf.d/cloudflare-set-real-ip.conf}"

if [ "$1" = "--cron" ]; then
    sleep $((RANDOM % 900))
fi

chmod 644 "$cf_ips"

for file in ips-v4 ips-v6; do
    curl --compressed -sLo- https://www.cloudflare.com/$file >> "$cf_ips"
    echo '' >> "$cf_ips"
done

sed -i -e 's/^/set_real_ip_from /g' -e 's/$/;/g' "$cf_ips"
sed -i -e '1i real_ip_header CF-Connecting-IP;'  "$cf_ips"

mv "$cf_ips" "$cf_ip_config"
