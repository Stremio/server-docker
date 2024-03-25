# The Stremio streaming Server Docker image
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/stremio/server?label=stremio%2Fserver%3Alatest)](https://hub.docker.com/r/stremio/server)

## Run the image

`docker run --rm -d -p 11470:11470 -p 12470:12470 stremio/server:latest`

If you're running `stremio-web` locally then you should disable CORS on the server by passing `NO_CORS=1` to the env. variables:

`docker run --rm -d -p 11470:11470 -p 12470:12470 -e NO_CORS=1 stremio/server:latest`

Available ports:
- 11470 - http
- 12470 - https

Env. variables:

`FFMPEG_BIN` - full path to the ffmpeg binary, on platforms where it cannot be reliably determined by the ffmpeg-static package (e.g. darwin aarch64)

`FFPROBE_BIN` - full path to the ffprobe binary

`APP_PATH` - custom application path for storing server settings, certificates, etc

`NO_CORS` - if set to any value it will disable the CORS checks on the server.

## Build image

Docker image can be easily built using the included [`Dockerfile`](./Dockerfile).

By default, the image has `ffmpeg` installed with a specific version of `ffmpeg-jellyfin`,
for more information check the `Dockerfile`.

For the **desktop build** (currently, the only supported platform) do not pass the `BUILD` argument.

### Example: Build a Docker image with Server v4.20.1

**NB:** On a new Ubuntu release you must update the [`setup_jellyfin_repo.sh`](./setup_jellyfin_repo.sh) shell script for `jellyfin-ffmpeg`.

If you're cross-building the image from x86 to arm, you need to either use a [QEMU binary or `multiarch/qemu-user-static` (see below)](#cross-building)

- Platform: `linux/amd64` (also used for `linux/x86_64`):

`docker buildx build --platform linux/amd64 --build-arg VERSION=v4.20.1 -t stremio/server:latest .`

- Platform: `linux/arm64` (alias of `linux/arm64/v8`):

`docker buildx build --platform linux/arm64 --build-arg VERSION=v4.20.1 -t stremio/server:latest .`

- Platform `linux/arm/v7`:

`docker buildx build --platform linux/arm/v7 --build-arg VERSION=v4.20.1 -t stremio/server:latest .`

### Cross building
Cross building the image from an `x86` to `arm` architecture, you need to either use QEMU emulation binary or the `multiarch/qemu-user-static` docker image.

#### Using QEMU

Setup `binfmt` if you're not on Docker Desktop, if you are you can skip this step.
See https://docs.docker.com/build/building/multi-platform/#qemu for more details.

`docker run --privileged --rm tonistiigi/binfmt --install all`

- arm/v7
  `docker buildx build --platform linux/arm/v7 --build-arg VERSION=v4.20.1 -t stremio/server:latest .`

- arm64 / arm64/v8
  `docker buildx build --platform linux/arm64 --build-arg VERSION=v4.20.1 -t stremio/server:latest .`

#### Using `multiarch/qemu-user-static` image

For more details check https://github.com/multiarch/qemu-user-static.

`docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`

- Build a Docker image with a local `server.js` found in the root of the folder:
**Note:** By passing an empty `VERSION` argument you will skip downloading the `server.js` from AWS before overriding it with your local one.

`docker buildx build --build-arg VERSION= -t stremio/server:latest .`

#### Arguments

- `VERSION` - specify which version of the `server.js` you'd like to be downloaded for the docker image.
- `BUILD` - For which platform you'd like to download the `server.js`.

Other arguments:

- `NODE_VERSION` - the version which will be included in the image and `server.js` will be ran with.
- `JELLYFIN_VERSION` - `jellyfin-ffmpeg` version, we currently require version **<= 4.4.1**.

## Publishing on Docker Hub

New releases of Stremio Server are automatically released in Docker Hub using the [publish.yml](./.githib/workflows/publish.yml) using a custom event type called "new-release" and client payload containing the release tag version.

You can also manually trigger this action with curl and a Personal Access Token generated from Github:
```
curl -L
   -X POST
   -H "Accept: application/vnd.github+json"
   -H "Authorization: Bearer PERSONAL_ACCESS_TOKEN"
   -H "X-GitHub-Api-Version: 2022-11-28"
   https://api.github.com/repos/stremio/server-docker/dispatches
   -d '{"event_type":"new-release","client_payload":{"tag": "v4.20.3"}}'
```

### Build images manually

1. Update version tag:

`docker buildx build --push --platform linux/arm64,linux/arm/v7,linux/amd64 --build-arg VERSION=v4.20.1 -t stremio/server:4.20.1 .`

2. Update latest tag:


`docker buildx build --push --platform linux/arm64,linux/arm/v7,linux/amd64 --build-arg VERSION=v4.20.1 -t stremio/server:latest .`
