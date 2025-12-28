# Ubuntu 20.04 (Xavier embedded)

## Podman
```bash
# run everything as root, it will make it easier
sudo su

# requirements
apt-get install -y curl wget gnupg2

# source the ubuntu release
source /etc/os-release

# add the podman repository
sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"

# add the GPG key
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | apt-key add -

apt-get update
apt-get install -y podman
```

### Setup nvidia runtime
You should be able to follow this guide for the most part (maybe not hello world)
https://nvidia.github.io/container-wiki/toolkit/jetson.html

You most likely need these packages installed
```bash
sudo apt-get install -y libnvidia-container-tools libnvidia-container0 nvidia-container-runtime nvidia-container-runtime-hook nvidia-docker2
```

This command should print something:
```bash
sudo docker info | grep nvidia
# Runtimes: io.containerd.runc.v2 nvidia runc
```

You also need to configure podman in order to have the correct runtime(s) available.
In order to do this you can edit the file in `/usr/share/containers/containers.conf` 
Under the `[engine.runtimes]` section simply uncomment crun:
```conf
crun = [
  "/usr/bin/crun",
]
```

And add the nvidia runtime
```conf
nvidia = [
  "/usr/bin/nvidia-container-runtime",
]
```

Have a look at [containers.conf](.config/containers/containers.conf) for an example config

### Start the service(s)
podman-compose has commands to setup unit files for the services you wish to start on boot.
cockpit-podman however has no support for users, it will only use the root socket for the containers, so the only solution is to run the containers as root and pass the uid and gid to the containers.

podman-compose's commands to setup unit files doesn't work on root, so you could run the commands as any user and just move/copy the files.

[podman-compose@.service](./units/podman-compose@.service) will look for `~/.config/containers/compose/projects/*.env` files and automatically add a service for each file that exist there, since the service has to be run as root `~/` will be `/root/`.

The .env files are very simple, they just tell the service which files to use
```
COMPOSE_PROJECT_DIR=/home/xavier/podman/dashy
COMPOSE_FILE=dashy.yaml
COMPOSE_PATH_SEPARATOR=:
COMPOSE_PROJECT_NAME=dashy
```

```bash
# You need to run this for each service you wish to run on boot
systemctl enable podman-compose@dashy
systemctl start podman-compose@dashy
```

## Cockpit
```bash
sudo apt-get install cockpit
```

### cockpit-podman
Update and install nodejs (nodejs 10 has been in EOL since April 2021)

```bash
# requirements
sudo apt-get install -y ca-certificates curl gnupg

# add nodesource GPG key
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# add the nodejs repository
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

# install nodejs
sudo apt-get update
sudo apt-get install -y nodejs
```

Now you can build cockpit-podman from source
```bash
# requirements
sudo apti-get install -y gettext nodejs make

# clone the cockpit-podman repo
git clone https://github.com/cockpit-project/cockpit-podman

# apply the patch from the repo (patches/cockpit-podman.patch)
patch -p1 < cockpit-podman.patch

# build it
cd cockpit-podman
make
```

### Start the service
```bash
systemctl enable cockpit
systemctl start cockpit
```

