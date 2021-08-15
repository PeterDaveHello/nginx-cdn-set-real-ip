#!/bin/bash

cf_ips="$(mktemp)"
cf_ip_config="${cf_ip_config:-/etc/nginx/conf.d/cloudflare-set-real-ip.conf}"

if [ "$1" = "--cron" ]; then
    sleep $((RANDOM % 900))
fi

chmod 644 "$cf_ips"

curl --compressed -sLo- https://www.cloudflare.com/ips-v4 >> "$cf_ips"
curl --compressed -sLo- https://www.cloudflare.com/ips-v6 >> "$cf_ips"
sed -i -e 's/^/set_real_ip_from /g' -e 's/$/;/g' "$cf_ips"
sed -i -e '1i real_ip_header CF-Connecting-IP;'  "$cf_ips"

mv "$cf_ips" "$cf_ip_config"
