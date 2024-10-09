# Copyright (C) 2017-2023 Smart code 203358507

# the node version for running the server
ARG NODE_VERSION=14

FROM node:$NODE_VERSION

ARG VERSION=master
# Which build to download for the image,
# possible values are: desktop, android, androidtv, webos and tizen
# webos and tizen require older versions of node:
# - Node.js `v0.12.2` for WebOS 3.0 (2016 LG TV)
# - Node.js `v4.4.3` for Tizen 3.0 (2017 Samsung TV)
# But, as of writing this, we only support desktop!
ARG BUILD=desktop

LABEL com.stremio.vendor="Smart Code Ltd."
LABEL version=${VERSION}
LABEL description="Stremio's streaming Server"

SHELL ["/bin/sh", "-c"]

CMD ["bash"]

WORKDIR /stremio

# We require version <= 4.4.1
# https://github.com/jellyfin/jellyfin-ffmpeg/releases/tag/v4.4.1-4
ARG JELLYFIN_VERSION=4.4.1-4

# SHELL ["/bin/bash", "-c"]

# COPY qemu-arm-static /usr/bin/qemu-arm-static


# RUN apt update and install wget
RUN apt -y update && apt -y install wget
RUN wget https://repo.jellyfin.org/archive/ffmpeg/debian/${JELLYFIN_VERSION}/jellyfin-ffmpeg_${JELLYFIN_VERSION}-$(dpkg --status tzdata|awk -F'[:-]' '$1=="Provides"{print $NF}')_$(dpkg --print-architecture).deb -O jellyfin-ffmpeg_${JELLYFIN_VERSION}-$(dpkg --status tzdata|awk -F'[:-]' '$1=="Provides"{print $NF}').deb
RUN apt -y install ./jellyfin-ffmpeg_${JELLYFIN_VERSION}-$(dpkg --status tzdata|awk -F'[:-]' '$1=="Provides"{print $NF}').deb
RUN rm jellyfin-ffmpeg_${JELLYFIN_VERSION}-$(dpkg --status tzdata|awk -F'[:-]' '$1=="Provides"{print $NF}').deb

# RUN apt install -y bash
COPY download_server.sh download_server.sh
# RUN /bin/bash -c download_server.sh
RUN ./download_server.sh

# This copy could will override the server.js that was downloaded with the one provided in this folder
# for custom or manual builds if $VERSION argument is not empty.
COPY . .

VOLUME ["/root/.stremio-server"]

# HTTP
EXPOSE 11470

# HTTPS
EXPOSE 12470

# full path to the ffmpeg binary
ENV FFMPEG_BIN=

# full path to the ffprobe binary
ENV FFPROBE_BIN=

# Custom application path for storing server settings, certificates, etc
ENV APP_PATH=

# Use `NO_CORS=1` to disable the server's CORS checks
ENV NO_CORS=

# "Docker image shouldn't attempt to find network devices or local video players."
# See: https://github.com/Stremio/server-docker/issues/7
ENV CASTING_DISABLED=1

ENTRYPOINT [ "node", "server.js" ]
