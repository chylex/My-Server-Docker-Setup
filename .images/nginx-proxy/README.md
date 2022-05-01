This image contains an [nginx](https://www.nginx.com/) reverse proxy that provides HTTP / HTTPS access to web servers in containers.

# Environment Variables

- `SERVER_NAME` is the hostname you will use to access your service. You may include multiple space-separated hostnames if you want the proxy to respond to all of them.
  - Default: `localhost`
  - Example: `example.com`
  - Example: `example.com alternative.example.com`
- `SERVER_PORT` is the port you will use to access your service. It must match the port in the `ports:` section in `docker-compose.yml`.
  - Default: `80`
- `UPSTREAM` is the hostname and port of the internal service. The hostname is the name of the service container in `docker-compose.yml`. 
  - Example: `server:8080`
- `SSL_CERT` is the path to the your SSL certificate file in the proxy container. If you have a fullchain certificate, use that.
  - Optional
  - Example: `/certs/cert.pem`
  - Example: `/certs/fullchain.pem`
- `SSL_CERT_KEY` is the path to your SSL certificate's private key file in the proxy container.
  - Optional
  - Example: `/certs/privkey.pem`
- `TZ` is the server's timezone.
  - Default: `UTC`
  - Example: `Europe/Prague`

# Ports

By default, services are configured to listen on `http://localhost:<port>`, where `<port>` is a dedicated port documented in the service's `README`. Since the proxy only listens on a single port, it can only handle either HTTP or HTTPS, but not both.

If you want to separate services by hostnames instead of ports and/or listen on standard ports with an HTTP to HTTPS redirect, you will need to run a single reverse proxy container that listens on ports `80` and `443`, and connect it to all containers that you want to serve through the reverse proxy. However, that is outside the scope of this guide.

# Logs

By default, services that use this image store [nginx](https://www.nginx.com/) log files `access.log` and `error.log` in `/srv/<service>/proxy/`.

The current configuration does not have any log rotation, so the two log files will grow indefinitely. Eventually I will add a guide for how you can use [logrotate](https://linux.die.net/man/8/logrotate) to separate log files by date, and automatically delete old logs.

# Enable HTTPS

By default, services in this repository use HTTP. To use HTTPS instead, you will need to:

1. Get a domain
2. Get an SSL certificate (for example from [Let's Encrypt](https://letsencrypt.org/))
3. Place the certificate file and private key file in a folder that will be mounted as a volume
4. Make sure the `app_ssl_certs` group, which is created as part of the setup script of services using this image, can read the files; for ex.:
   ```bash
   /usr/bin/chgrp app_ssl_certs /app/.certs/*
   /usr/bin/chmod 640           /app/.certs/*
   ```
5. Create a `docker-compose.override.yml` file next to the service's `docker-compose.yml` file, with the following contents:
   ```yml
   services:
     proxy:
       volumes:
         - /app/.certs:/certs:ro
       environment:
         SERVER_NAME: "example.com"
         SSL_CERT: "/certs/fullchain.pem"
         SSL_CERT_KEY: "/certs/privkey.pem"
   ```
6. Run `docker compose up -d` to restart the proxy

This example puts certificates for `example.com` into `/app/.certs`, mounts it in the `/certs` folder in the proxy container, and configures the environment variables. You will need to adjust the paths and server name, and you may also need to adjust `proxy:` to match the name of the proxy container in the service's `docker-compose.yml`.

To renew certificates, you will need to:

1. Upload the new certificates into the designated folder, and ensure the permissions are still correct
2. Run `docker exec <container-name> nginx -s reload`, substituting `<container-name>` for the full name of the proxy container

This image only enables TLS 1.2 and 1.3 by default. If you need to allow older versions, you can edit the `ssl_protocols` property in [ssl.conf](conf/ssl.conf).
