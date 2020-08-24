#!/bin/bash

cf_ips="$(mktemp)"
cp_ip_config="/etc/nginx/conf.d/cloudflare-set-real-ip.conf"

curl --compressed -sLo- https://www.cloudflare.com/ips-v4 >> "$cf_ips"
curl --compressed -sLo- https://www.cloudflare.com/ips-v6 >> "$cf_ips"
sed -i -e 's/^/set_real_ip_from /g' -e 's/$/;/g' "$cf_ips"
sed -i -e '1i real_ip_header CF-Connecting-IP;'  "$cf_ips"

mv "$cf_ips" "$cp_ip_config"
