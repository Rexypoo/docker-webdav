FROM golang AS build

WORKDIR /build
ADD https://raw.githubusercontent.com/Rexypoo/simple-webdav/main/webdav.go /build/webdav.go

RUN go mod init webdav.go \
 && go mod tidy \
 && CGO_ENABLED=0 go build webdav.go

FROM alpine AS clean
WORKDIR /dav
COPY --from=build /build/webdav /usr/local/bin/webdav

FROM clean AS drop-privileges

# Create user
ENV USER=webdav \
    UID=16026 \
    TEMPLATE=/dav
# Whoever owns /dav owns the instance

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --no-create-home \
    --uid "$UID" \
    "$USER" \
 && mkdir "$TEMPLATE" \
 && chown -R "$USER":"$USER" .

ADD https://raw.githubusercontent.com/Rexypoo/docker-entrypoint-helper/master/entrypoint-helper.sh /usr/local/bin/entrypoint-helper.sh
RUN chmod u+x /usr/local/bin/entrypoint-helper.sh
ENTRYPOINT ["entrypoint-helper.sh", "/usr/local/bin/webdav"]

FROM gcr.io/distroless/static:nonroot AS distroless
WORKDIR /
COPY --from=build /build/webdav /usr/local/bin/webdav
entrypoint ["webdav"]

FROM gcr.io/distroless/static:debug AS debug
WORKDIR /
COPY --from=build /build/webdav /usr/local/bin/webdav
entrypoint ["webdav"]

# Build with 'docker build -t webdav .'
LABEL org.opencontainers.image.url="https://hub.docker.com/r/rexypoo/webdav" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/rexypoo/webdav" \
      org.opencontainers.image.source="https://github.com/Rexypoo/docker-webdav" \
      org.opencontainers.image.version="0.1a" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="Webdav on Docker (golang.org/x/net)" \
      org.opencontainers.image.title="rexypoo/webdav" \
      org.label-schema.docker.cmd='mkdir -p "$HOME"/Shared/dav && \
      docker run -d --rm \
      --name webdav \
      --publish 8080:80 \
      -v "$HOME"/Shared/dav:/dav \
      rexypoo/webdav' \
      org.label-schema.docker.cmd.devel="docker run -it --rm --entrypoint bash rexypoo/webdav" \
      org.label-schema.docker.cmd.debug="docker exec -it webdav bash"
