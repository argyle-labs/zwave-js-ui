# TODO: base image + build for zwave-js-ui. Mirror jellyfin/Dockerfile conventions.
FROM debian:12-slim
LABEL org.opencontainers.image.source="https://github.com/argyle-labs/zwave-js-ui"
EXPOSE 8091
