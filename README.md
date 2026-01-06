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
```bash
podman-compose systemd -a create-unit
podman-compose systemd -a register # for each service you wish to run
```

[podman-compose@.service](./units/podman-compose@.service) will look for `~/.config/containers/compose/projects/*.env` files and automatically add a service for each file that exist there.

The .env files are very simple, they just tell the service which files to use
```
COMPOSE_PROJECT_DIR=/home/xavier/podman/homepage
COMPOSE_FILE=homepage.yaml
COMPOSE_PATH_SEPARATOR=:
COMPOSE_PROJECT_NAME=homepage
```

```bash
# You need to run this for each service you wish to run on boot
systemctl --user enable podman-compose@homepage
systemctl --user start podman-compose@homepage
```

I still haven't figured out how to have podman rootless working with runtime nvidia so the jellyfin-jetson container has to be ran as root, while the standard jellyfin image doesn't have to be.

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

## Services
### Jellyfin
Jellyfin's patched ffmpeg has no hardware codec support on Jetson boards.

You need [jellyfin-ffmpeg-jetson](https://github.com/mguzzina/jellyfin-ffmpeg-jetson), you can follow its build and installation guide:

Install requirements
```bash
sudo apt-get install -y cuda nvidia-l4t-jetson-multimedia-api cmake
```

Build jellyfin-ffmpeg-jetson
```bash
git clone https://github.com/mguzzina/jellyfin-ffmpeg-jetson.giti -b v7.1.3-1-jetson
cd jellyfin-ffmpeg-jetson
mkdir dist
./build r35.3.1 arm64-native dist
```
You should find a .deb file in the dist directory.

Build jellyfin-packaging-jetson
```bash
git clone https://github.com/mguzzina/jellyfin-packaging-jetson.git
cd jellyfin-packaging-jetson
./build.py 10.11.5 nvcr.io/nvidia/l4t-jetpack arm64 r35.3.1
```
You should find three .deb files in the out/nvcr.io/nvidia/l4t-jetpack directory.

To build the docker image you need to copy the deb files `jellyfin-web_*.deb`, `jellyfin-server_*.deb` and `jellyfin-ffmpeg*_*.deb` in jellyfin/debs.
```bash
cd jellyfin/debs
ghlight ExtraWhitespace ctermbg=red guibg=red
podman build -t jellyfin-jetson .
```

Since the jetson addition is not officially supported, you should really have the double option of standard image and nvmpi one.
In jellyfin/ you can find a jellyfin.yaml and a jellyfin-jetson.yaml as well as the two respective unit files in units/.

