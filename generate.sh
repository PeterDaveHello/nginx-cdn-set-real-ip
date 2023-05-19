#!/usr/bin/env bash

set -euo pipefail

temp_ips="$(mktemp)"
nginx_ip_conf_dir="${nginx_ip_conf_dir:-/etc/nginx/conf.d}"
sleep_secs="0"
trap 'rm -f "$temp_ips"' EXIT

for cmd in curl sed mv chmod rm cmp; do
    command -v "$cmd" >/dev/null || { echo >&2 "Error: $cmd not found. Please make sure it's installed and try again."; exit 1; }
done

declare -A CDN_NAME CDN_IP_HEADER

CDN_NAME["cf"]="Cloudflare"
CDN_IP_HEADER["cf"]="CF-Connecting-IP"

fetch_ip_list() {
    true > "$temp_ips"
    case $1 in
    "cf")
        for file in ips-v4 ips-v6; do
            curl --compressed -sLo- "https://www.cloudflare.com/$file" >> "$temp_ips"
            echo '' >> "$temp_ips"
        done
        ;;
    esac
}

for arg in "$@"; do
    case $arg in
    "--cron")
        sleep_secs="$((RANDOM % 900))"
        continue
        ;;
    esac
done

chmod 644 "$temp_ips"

sleep "$sleep_secs"

for cdn in "${!CDN_NAME[@]}"; do
    echo "Fetching ${CDN_NAME[$cdn]} IP addresses..."
    fetch_ip_list "$cdn"
    nginx_ip_conf="$nginx_ip_conf_dir/${CDN_NAME[$cdn],,}-set-real-ip.conf"
    echo "Generating nginx configuration file..."
    sed -i -e 's/^/set_real_ip_from /g' -e 's/$/;/g' -e "1i real_ip_header ${CDN_IP_HEADER[$cdn]};" "$temp_ips"

    if ! [ -e "$nginx_ip_conf" ]; then
        mv -f "$temp_ips" "$nginx_ip_conf"
        echo "Nginx configuration for ${CDN_NAME[$cdn]} IP addresses added successfully."
    elif cmp -s "$temp_ips" "$nginx_ip_conf"; then
        echo "No changes detected. We have nothing to do."
        rm -f "$temp_ips"
    else
        echo "${CDN_NAME[$cdn]} IP addresses config have changed. Updating nginx configuration..."
        mv -f "$temp_ips" "$nginx_ip_conf"
        echo "Nginx configuration for ${CDN_NAME[$cdn]} IP addresses updated successfully."
    fi
    echo
done
