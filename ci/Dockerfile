ARG GODOT_VERSION=4.7
ARG GODOT_RELEASE=stable
ARG DEBIAN_FRONTEND=noninteractive

# Runtime dependencies: Godot, export script, actions/checkout.
FROM ubuntu:24.04 AS runtime
ARG DEBIAN_FRONTEND
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git libfontconfig1 python3 \
 && rm -rf /var/lib/apt/lists/*

FROM ubuntu:24.04 AS downloads
ARG DEBIAN_FRONTEND
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*
ARG GODOT_VERSION
ARG GODOT_RELEASE
ENV GODOT_TAG=${GODOT_VERSION}-${GODOT_RELEASE}
ENV GODOT_URL=https://github.com/godotengine/godot/releases/download/${GODOT_TAG}
WORKDIR /dl

FROM downloads AS templates
RUN curl -fsSL "${GODOT_URL}/Godot_v${GODOT_TAG}_export_templates.tpz" -o templates.tpz
RUN unzip -q templates.tpz

# Godot editor binary per target architecture.
FROM downloads AS editor-amd64
ENV GODOT_ARCH=x86_64

FROM downloads AS editor-arm64
ENV GODOT_ARCH=arm64

FROM editor-${TARGETARCH} AS editor
RUN curl -fsSL "${GODOT_URL}/Godot_v${GODOT_TAG}_linux.${GODOT_ARCH}.zip" -o godot.zip
RUN unzip -q godot.zip
RUN mv "Godot_v${GODOT_TAG}_linux.${GODOT_ARCH}" godot

FROM runtime
ARG GODOT_VERSION
ARG GODOT_RELEASE
# Fixed data dir: CI container jobs override HOME.
ENV XDG_DATA_HOME=/opt/godot
COPY --from=templates /dl/templates /opt/godot/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}
COPY --from=editor /dl/godot /usr/local/bin/godot
WORKDIR /project
