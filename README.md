# The Stremio streaming server.js Docker image

## Build image

Docker image can be easily built using the included [`Dockerfile`](./Dockerfile)
and you need to use `BuildKit`.
By default, the image has `ffmpeg` installed with a specific version of `ffmpeg-jellyfin`,
for more information check the `Dockerfile`.

There is also a requirement to have a ssh public key on your host machine!

For desktop (currently only supported platform) build do not pass the `BUILD` argument:

`DOCKER_BUILDKIT=1 docker build --ssh default -t stremio/server:latest .`

#### Other arguments

`NODE_VERSION` - the version which will be included in the image and `server.js` will be ran with.
`NVM_VERSION` - `nvm` version to be used for managing `nodejs` versions.
`JELLYFIN_VERSION` - `jellyfin-ffmpeg` version, we currently require version **<= 4.4.1**.


`DOCKER_BUILDKIT=1 docker build --ssh default --build-arg VERSION= -t stremio/server:latest .`