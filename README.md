# nginx-cloudflare-set-real-ip

Generate config to set correct client IP address in nginx, based on Cloudflare's IP address and `CF-Connecting-IP` header.

The script will fetch the latest Cloudflare IP addresses and generate corresponding nginx config file in `/etc/nginx/conf.d/cloudflare-set-real-ip.conf`

Use a cronjob to trigger this IP update script periodically, and reload your nginx instance for the new config.

## Example

`/etc/cron.d/opt/nginx-cloudflare-set-real-ip`:

```cron
1 1 * * * root /opt/nginx-cloudflare-set-real-ip/generate.sh --cron && /usr/sbin/service nginx reload
```

## Reference

- https://www.cloudflare.com/ips/
- https://support.cloudflare.com/hc/en-us/articles/200170986-How-does-Cloudflare-handle-HTTP-Request-headers-
