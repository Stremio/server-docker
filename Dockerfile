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
LABEL description="Stremio's stremaing Server.js"

WORKDIR /stremio

# We require versoin <= 4.4.1
# https://github.com/jellyfin/jellyfin-ffmpeg/releases/tag/v4.4.1-4
ARG JELLYFIN_VERSION=4.4.1-4

RUN echo $(awk -F'=' '/^ID=/{ print $NF }' /etc/os-release)
RUN echo $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )
RUN echo $( dpkg --print-architecture )

RUN apt install curl gnupg ca-certificates git \
    && mkdir /etc/apt/keyrings \
    && curl -fsSL --insecure https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg

# Add the jellyfin repository
RUN echo "Types: deb\n"\
"URIs: https://repo.jellyfin.org/"$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )"\n"\
"Suites: "$( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )"\n"\
"Components: main \n"\
"Architectures: $( dpkg --print-architecture ) \n"\
"Signed-By: /etc/apt/keyrings/jellyfin.gpg" \
    >> jellyfin.sources \
    && mv jellyfin.sources /etc/apt/sources.list.d

RUN apt update \
    && apt install -y jellyfin-ffmpeg=$JELLYFIN_VERSION-$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)

# If we have VERSION set (i.e. different than empty), then we want to download it from AWS
RUN $(if [ -n "$VERSION" ] ; then wget https://dl.strem.io/server/${VERSION}/${BUILD}/server.js; fi)

# This copy could will override the server.js that was downloaded with the one provided in this folder
# for custom or manual builds if $VERSION argument is not empty.
COPY . .

VOLUME ["/root/.stremio-server"]

EXPOSE 11470

ENV FFMPEG_BIN=
ENV FFPROBE_BIN=
ENV APP_PATH=
ENV NO_CORS=

ENTRYPOINT [ "node", "server.js" ]