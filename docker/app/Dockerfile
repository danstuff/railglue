# syntax=docker/dockerfile:1
# One image for every app; mise installs each app's own tool versions.
FROM debian:trixie-slim

ARG MISE_VERSION=v2026.9.7
ARG UID=1000
ARG GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates chromium chromium-driver curl git \
        default-libmysqlclient-dev default-mysql-client libffi-dev \
        libgmp-dev libpq-dev libsqlite3-dev libssl-dev libvips libyaml-dev \
        pkg-config postgresql-client sqlite3 tzdata zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://mise.run \
    | MISE_VERSION="$MISE_VERSION" MISE_INSTALL_PATH=/usr/local/bin/mise sh

# Chromium cannot use its sandbox inside an unprivileged container.
RUN mkdir -p /etc/chromium.d \
    && echo 'export CHROMIUM_FLAGS="$CHROMIUM_FLAGS --no-sandbox' \
            '--disable-dev-shm-usage"' > /etc/chromium.d/railglue

RUN groupadd --non-unique --gid "$GID" railglue \
    && useradd --non-unique --create-home --uid "$UID" --gid "$GID" \
        --shell /bin/bash railglue \
    && mkdir -p /app /bundle /mise \
    && chown railglue:railglue /app /bundle /mise

COPY --chmod=755 bin/ /usr/local/bin/
COPY config.ru /usr/local/share/railglue/config.ru

ENV MISE_DATA_DIR=/mise \
    MISE_TRUSTED_CONFIG_PATHS=/app \
    MISE_IDIOMATIC_VERSION_FILE_ENABLE_TOOLS=ruby,node \
    MISE_YES=1 \
    BUNDLE_PATH=/bundle \
    BROWSER_PATH=/usr/bin/chromium \
    SE_BROWSER_PATH=/usr/bin/chromium \
    PATH=/mise/shims:$PATH

USER railglue
WORKDIR /app
ENTRYPOINT ["railglue-entrypoint"]
CMD ["railglue-serve"]
