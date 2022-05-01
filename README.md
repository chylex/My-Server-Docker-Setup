This repository contains configuration and setup guides for services that run on my personal server. Services are managed with [Docker Compose](https://docs.docker.com/compose/).

(*) The listed licenses only cover files in this repository. Services and local images, whose configuration and scripting is fully mine, are dedicated to the public domain. Those based on other open-source projects use a license compatible with the original project.

**Overview of all services in this repository (see [Services](#3-services) section):**

| Service | Description | License (*) | Rootless |
|---------|-------------|-------------|:--------:|
| TODO    |             |             |          |

**Overview of local images needed to build some of the services (see [Local Images](#31-local-images) section):**

| Image | Description | License (*)  |
|-------|-------------|--------------|
| TODO  |             |              |

# 1. Requirements

- Computer with an `x64` processor
- [Debian](https://www.debian.org/) (Bullseye or newer)
- [Docker Engine](https://docs.docker.com/engine/install/debian/) (latest)
- [Docker Compose](https://docs.docker.com/compose/install/) 2.5.0+

You can install [Docker Engine](https://docs.docker.com/engine/install/debian/) and [Docker Compose](https://docs.docker.com/compose/install/) by running this script as `root`

```bash
apt-get update
apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io

DOCKER_COMPOSE_URL=$(curl -sSL "https://api.github.com/repos/docker/compose/releases/latest" | grep -Eo "\"https://github.com/docker/compose/releases/download/(.*)/docker-compose-linux-x86_64\"" | sed -e 's|^"||' -e 's|"$||')

if [ -n "$DOCKER_COMPOSE_URL" ]; then
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "$DOCKER_COMPOSE_URL" -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
else
    echo "Could not automatically detect the latest version of Docker Compose!"
fi
```

This script is a mix of installation scripts for [Docker Engine](https://docs.docker.com/engine/install/debian/) and [Docker Compose](https://docs.docker.com/compose/install/), with an automatic detection of the latest version of [Docker Compose](https://docs.docker.com/compose/install/).

# 2. Configuration

## 2.1. Docker Daemon

I use the following Docker daemon configuration `/etc/docker/daemon.json`

```json
{
  "bip": "172.20.0.1/16",
  "default-address-pools": [{
    "base": "172.20.0.0/14",
    "size": 24
  }],
  "live-restore": true,
  "no-new-privileges": true
}
```

Using my configuration is optional, but at minimum I recommend enabling `no-new-privileges`.

Enabling `no-new-privileges` prevents processes in containers from gaining privileges, for ex. using `sudo`. Services in this repository assume that `no-new-privileges` is enabled by default. Containers that do need to gain privileges have `no-new-privileges` explicitly disabled in their `docker-compose.yml` configuration.

Enabling `live-restore` keeps containers alive while you install non-major Docker updates (see [Live Restore](https://docs.docker.com/config/containers/live-restore/) for additional details and caveats).

The `bip` property assigns the IPv4 range `172.20.0.0` - `172.20.255.255` to the default bridge network.

The `default-address-pools` property assigns the IPv4 range `172.21.0.0` - `172.23.255.255` to individual networks, allowing 768 networks of up to 255 containers each. Docker's default configuration has a limit of only 31 individual networks, and they use IPs from two ranges `172.17.x.x` and `192.168.x.x`, which can be annoying to work with.

If you change `/etc/docker/daemon.json`, run `systemctl restart docker` to apply the changes.

## 2.2. Networking

I use [BBR](https://github.com/google/bbr) for TCP congestion control, which I found to be much better for high traffic services like Minecraft servers. You can enable it by running this script as `root`

```bash
cat >> /etc/sysctl.conf <<'EOL'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOL

sysctl -p
```

The script simply adds two lines to `/etc/sysctl.conf` and applies the changes. Before you run it, make sure the file doesn't already contain those two lines; if it does, edit them manually and run just `sysctl -p`.

# 3. Services

Services are organized into folders. Each folder contains a `docker-compose.yml` file, a `README` with a setup script and important information, a `LICENSE` file that covers everything in the folder, and everything else needed to build and configure the service.

I will be using a few conventions:

- Service configuration is stored in `/app/<service>`
- Persistent service data is stored in `/srv/<service>`
- Every service folder in `/app` and `/srv` is owned by `root` and its permissions are `rwx-r-x---` (`chmod 750`)
- Users and groups dedicated to services begin with `app_` and use UID/GID in the `900`-`990` range
- Publicly exposed ports are in the `2000`-`2099` range

## 3.1. Local Images

Some services depend on local images, which are organized into folders in the [.images](.images) folder in this repository. Before you continue, copy the `.images` folder into `/app/.images`.

If a service depends on one of these images, it will be built as part of its setup script. Tags of local images are prefixed with `local/`.

There is also script `.images/build.sh` that lets you build a single image by specifying its name as a parameter to the script, or all images if no parameter is provided. You can use this to update a specific image to the latest version, and then restart containers that use the image.

## 3.2. Service Setup

Scripts for setting up services will be using the following Bash functions. You can copy/paste them directly into your terminal, or put them into `~/.bashrc` if you want them to be available all the time.

```bash
makefile() {
    touch "$1"
    chmod "$2" "$1"
    chown "$3" "$1"
}

makedir() {
    mkdir -p "$1"
    chmod "$2" "$1"
    chown "$3" "$1"
}

makesysgroup() {
    groupadd "$1" --gid $2 --system
}

makesysuser() {
    useradd "$1" --uid $2 --gid $3 --system --shell /bin/false
}

makesysusergroup() {
    makesysgroup "$1" "$2"
    makesysuser "$1" "$2" "$2"
}
```

To setup a service:

1. Use `makedir /app/<service> 750 root:root` to create a folder for the service configuration, substituting `<service>` for the name of the service
2. Copy all files from the service's folder in this repository into `/app/<service>`
3. View the `README.md` file in the service's folder for a setup script, and additional instructions and tips

The end of every setup script launches the service and starts watching logs of all of its containers. To stop watching logs, press `CTRL + C`.

## 3.3. Limits

Every container has a hard limit for RAM usage (`mem_limit`) with no swap allowance (`memswap_limit = mem_limit`). If a container tries using more RAM than its limit, it will be terminated and restarted. You may want to tweak these based on how much RAM is available on your system. In some cases, the limits might be too low to cover all possible scenarios; if a container runs out of memory, please open an issue.

## 3.4. Automatic Restarting

Every container is configured to restart automatically if it stops (`restart: "always"`). There is no limit for how many times it will restart, so you should watch the container whenever you start it to make sure it's not immediately crashing due to for ex. file permission errors.
