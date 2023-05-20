#!/usr/bin/env bash

set -euo pipefail

temp_ips="$(mktemp)"
nginx_ip_conf_dir="${nginx_ip_conf_dir:-/etc/nginx/conf.d}"
sleep_secs="0"
trap 'rm -f "$temp_ips"' EXIT

for cmd in curl sed mv chmod rm cmp; do
    command -v "$cmd" >/dev/null || { echo >&2 "Error: $cmd not found. Please make sure it's installed and try again."; exit 1; }
done

declare -A CDN_NAME CDN_IP_HEADER REQUESTED_CDN

CDN_NAME["cf"]="Cloudflare"
CDN_IP_HEADER["cf"]="CF-Connecting-IP"

CDN_NAME["fastly"]="Fastly"
CDN_IP_HEADER["fastly"]="Fastly-Client-IP"

fetch_ip_list() {
    true > "$temp_ips"
    case $1 in
    "cf")
        for file in ips-v4 ips-v6; do
            curl --compressed -sLo- "https://www.cloudflare.com/$file" >> "$temp_ips"
            echo '' >> "$temp_ips"
        done
        ;;
    "fastly")
        curl --compressed -sLo- https://api.fastly.com/public-ip-list | \
            awk -F'[]["]' '{for(i=1;i<=NF;i++) if ($i ~ /.*\/.*/) print $i}' | \
            sed 's/,\|\"//g' >> "$temp_ips"
        ;;
    esac
}

help() {
    echo >&2
    echo >&2 "This tool help generates nginx config file that sets the correct client IP address based on CDN provider's IP addresses and the corresponding header."
    echo >&2 ""
    echo >&2 "You need to give me at least one of supported CDN providers here to generate the config."
    echo >&2 ""
    echo >&2 "Usage:"
    echo >&2 ""
    echo >&2 "$0 [--cron] <CDN> [[CDN] [CDN]]"
    echo >&2 ""
    echo >&2 "Supported CDN:"
    echo >&2 ""
    for cdn in "${!CDN_NAME[@]}"; do
        echo >&2 "- $cdn (${CDN_NAME[$cdn]}, using http header ${CDN_IP_HEADER[$cdn]})"
    done
}

for arg in "$@"; do
    case $arg in
    "-h"|"--help")
        help
        exit
        ;;
    "--cron")
        sleep_secs="$((RANDOM % 900))"
        continue
        ;;
    esac

    if [ ! -v 'CDN_NAME["$arg"]' ]; then
        echo >&2 "\"$arg\" is not in the supported CDN list nor the supported argument, skipped..."
        continue
    fi
    REQUESTED_CDN[$arg]=1
done

chmod 644 "$temp_ips"

if [ ! -v 'REQUESTED_CDN[@]' ]; then
    echo >&2
    echo >&2 "No valid CDN found!"
    help
    exit 1
fi

sleep "$sleep_secs"
echo "Start nginx real client ip config generation..."

mkdir -p "$nginx_ip_conf_dir"

for cdn in "${!REQUESTED_CDN[@]}"; do
    nginx_ip_conf="$nginx_ip_conf_dir/${CDN_NAME[$cdn],,}-set-real-ip.conf"
    echo
    echo "Config target: $nginx_ip_conf"
    echo
    echo "Fetching ${CDN_NAME[$cdn]} IP addresses..."
    fetch_ip_list "$cdn"
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
done
