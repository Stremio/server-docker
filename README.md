# The Stremio streaming server.js Docker image

[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/stremio/server?label=stremio%2Fserver%3Alatest)](https://hub.docker.com/r/stremio/server)

## Build image

Docker image can be easily built using the included [`Dockerfile`](./Dockerfile).

By default, the image has `ffmpeg` installed with a specific version of `ffmpeg-jellyfin`,
for more information check the `Dockerfile`.

For the desktop build (currently, the only supported platform) do not pass the `BUILD` argument:

- Build docker image with `server.js` version `v4.19.0`:

`docker build --build-arg VERSION=v4.19.0 -t stremio/server:latest .`

- Build a Docker image with a local `server.js` found in the root of the folder:
**Note:** By passing an empty `VERSION` argument you will skip downloading the `server.js` from AWS before overriding it with your local one.

`docker build --build-arg VERSION= -t stremio/server:latest .`

#### Arguments

- `VERSION` - specify which version of the `server.js` you'd like to be downloaded for the docker image.
- `BUILD` - For which platform you'd like to download the `server.js`.

Other arguments:

- `NODE_VERSION` - the version which will be included in the image and `server.js` will be ran with.
- `NVM_VERSION` - `nvm` version to be used for managing `nodejs` versions.
- `JELLYFIN_VERSION` - `jellyfin-ffmpeg` version, we currently require version **<= 4.4.1**.


## Run the image

`docker run --rm -d -p 11470:11470 stremio/server:latest`