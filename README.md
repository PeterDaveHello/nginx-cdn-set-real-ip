# nginx-cdn-set-real-ip

This script generates an nginx configuration file that sets the correct client IP address based on CDN's IP addresses and the corresponding header.

## Supported CDN

- Cloudflare

## Usage

You can either clone this repository to your server, or download the script directly from the repository:

```sh
# Clone the repository
git clone https://github.com/PeterDaveHello/nginx-cdn-set-real-ip /opt/nginx-cdn-set-real-ip

# OR download the script directly
mkdir -p /opt/nginx-cdn-set-real-ip/
curl -sLo /opt/nginx-cdn-set-real-ip/generate.sh https://raw.githubusercontent.com/PeterDaveHello/nginx-cdn-set-real-ip/master/generate.sh
```

> Note: The `/opt` directory may require root privileges to write to. If you encounter permission errors, you may need to run the above commands with `sudo`.

Then add a cronjob to trigger the IP update script periodically and reload nginx for the new config. For example, create `/etc/cron.d/opt/nginx-cdn-set-real-ip` with the following contents:

```cron
1 1 * * * root /opt/nginx-cdn-set-real-ip/generate.sh --cron && /usr/sbin/service nginx reload
```

This will run the script every day at 01:01 AM and reload nginx with the new configuration.

## How it Works

The script fetches the latest CDN IP addresses from official sources and generates an nginx configuration file in `/etc/nginx/conf.d/cdn-set-real-ip.conf`.

It uses the `set_real_ip_from` directive to specify the trusted CDN IP addresses and the `real_ip_header` directive to set the corresponding header as the source of the real IP address.

If there are no changes to the CDN IP addresses, the script will exit without updating the configuration file.

## Reference

### Cloudflare

- <https://www.cloudflare.com/ips/>
- <https://support.cloudflare.com/hc/en-us/articles/200170986-How-does-Cloudflare-handle-HTTP-Request-headers->
