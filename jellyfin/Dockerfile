# Docker build arguments
ARG L4T_IMAGE=nvcr.io/nvidia/l4t-jetpack
ARG IMAGE_VERSION=r35.3.1

FROM ${L4T_IMAGE}:${IMAGE_VERSION}

ARG DEBS_DIR=debs

COPY ${DEBS_DIR} debs/

RUN ./${DEBS_DIR}/install_debs.bash

RUN rm -rf ${DEBS_DIR}

RUN apt-get update && apt-get install -y curl

#ARG UID
#ARG GID
#ARG USER=xavier
#RUN groupadd -g $GID -o $USER
#RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER
#RUN usermod -aG jellyfin $USER
#USER $USER

ARG JELLYFIN_FFMPEG_PATH=/usr/lib/jellyfin-ffmpeg
ENV PATH=$PATH:$JELLYFIN_FFMPEG_PATH
ENV JELLYFIN_WEB_DIR=/usr/share/jellyfin/web

ENTRYPOINT ["/bin/bash", "-c", "jellyfin"]
