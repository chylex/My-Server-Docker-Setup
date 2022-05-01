# Airsonic

[Airsonic Advanced](https://github.com/airsonic-advanced/airsonic-advanced) is a music streaming server compatible with Subsonic.

## Containers

- `server`
  - [Airsonic Advanced](https://github.com/airsonic-advanced/airsonic-advanced) server.
- `proxy`
  - Reverse proxy that provides HTTP or HTTPS access to the server.
  - Read the [nginx-proxy](../.images/nginx-proxy) page for important information.

## Setup

```bash
# Build local images
if [ -z "$(docker images -q local/nginx-proxy)" ]; then /app/.images/build.sh nginx-proxy; fi

# Create users and groups
makesysgroup     app_ssl_certs    901
makesysusergroup app_airsonic     910
makesysuser      app_airsonic_www 911 app_ssl_certs

# Create data folders
makedir /srv/airsonic           750 root:root
makedir /srv/airsonic/server    750 app_airsonic:root
makedir /srv/airsonic/music     750 app_airsonic:root
makedir /srv/airsonic/podcasts  750 app_airsonic:root
makedir /srv/airsonic/playlists 750 app_airsonic:root
makedir /srv/airsonic/proxy     750 app_airsonic_www:root

# Fix permissions on included scripts
chmod 750 /app/airsonic/permissions.sh

# Start the service
cd /app/airsonic && docker compose up -d && docker compose logs -f
```

This starts an HTTP server on port `2010`. You can now visit <http://localhost:2010> and setup the admin account. Ensure nobody else can access the server until you configure it.

The `server` container is configured with a hard limit of `1 GB` RAM, with `256 MB` allocated to the JVM heap. If you have a large music library, you might have to increase the limit. To increase the limit to `2 GB`, create a `docker-compose.override.yml` file with the following contents:

```yml
services:
  server:
    mem_limit: 2G
    memswap_limit: 2G
```

## Music

Music is stored in `/srv/airsonic/music`.  
I would recommend organizing your music as follows: `/srv/airsonic/music/<artist>/<album>/<song>`

1. Upload your music into the folder
2. Run the `permissions.sh` script to fix ownership and permissions
3. Visit your Airsonic server, go to Settings, and click **Scan media folders now** to refresh
4. For large music libraries, you can watch the scanning progress in the logs

The `permissions.sh` script sets ownership and permissions in music, podcasts, and playlists folders. This setup requires minimal effort if you're a single user and don't update your music collection very frequently. For higher demand scenarios, you may want to for ex. setup an FTP server to allow multiple users to upload their music, but that's beyond the scope of this guide.
