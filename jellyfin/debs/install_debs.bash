#! /bin/bash

set -eou pipefail

SCRIPT_DIR=$(dirname "$0")

apt-get update && apt-get install -y $SCRIPT_DIR/jellyfin-server_*.deb $SCRIPT_DIR/jellyfin-web_*.deb $SCRIPT_DIR/jellyfin-ffmpeg*_*.deb
