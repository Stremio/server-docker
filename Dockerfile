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

# We require versoin <= 4.4.1
# https://github.com/jellyfin/jellyfin-ffmpeg/releases/tag/v4.4.1-4
ARG JELLYFIN_VERSION=4.4.1-4

# SHELL ["/bin/bash", "-c"]

# COPY qemu-arm-static /usr/bin/qemu-arm-static

COPY setup_jellyfin_repo.sh setup_jellyfin_repo.sh

RUN ./setup_jellyfin_repo.sh
# No need for updating because the shell script above does that for us.
# RUN apt update

RUN apt install -y jellyfin-ffmpeg=$JELLYFIN_VERSION-$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)

# RUN apt install -y bash
COPY download_server.sh download_server.sh
# RUN /bin/bash -c download_server.sh
RUN ./download_server.sh
# If we have VERSION set (i.e. different than empty), then we want to download it from AWS
# RUN $(if [ -n "$VERSION" ] ; then wget https://dl.strem.io/server/${VERSION}/${BUILD}/server.js; fi)

# This copy could will override the server.js that was downloaded with the one provided in this folder
# for custom or manual builds if $VERSION argument is not empty.
COPY . .

VOLUME ["/root/.stremio-server"]

# HTTP
EXPOSE 11470

# HTTPS
EXPOSE 12470

# UDP Multicast port
EXPOSE 5353

ENV FFMPEG_BIN=
ENV FFPROBE_BIN=
ENV APP_PATH=

# Use `NO_CORS=1` to disable the server's CORS checks
ENV NO_CORS=

ENTRYPOINT [ "node", "server.js" ]