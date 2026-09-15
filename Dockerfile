# syntax=docker/dockerfile:1

# The competitor guide, built. The output is `book/`, which a deployment serves and the local stack
# mounts at /docs.
#
# WHY THIS EXISTS. Two of this book's inputs are other repositories' build output -- the replay
# viewer, and the `tinybrains` binary that plays the lesson replays -- and both used to be reached
# through a sibling checkout: `../ants/viz/dist` and `cargo install --path ../../devops/cli`. So
# building the book required the platform checked out around it, and `src/viz/` and `src/tutorials/`
# were committed to spare everyone that. They are now taken from artifact images, and neither is
# committed.
#
# A LESSON REPLAY IS ENGINE OUTPUT, exactly as the reference observations are: it is produced by
# playing a written script through the real cartridge, so what a page shows is what the rules do
# rather than a drawing of what someone believed they do. That is also why it goes stale when the
# engine changes -- and why the digest check at the end of tutorials/build.sh is not optional. A
# viewer re-simulating with a different engine does not fail: it draws a plausible match that never
# happened.

ARG ANTS_REF=tinybrains/ants:dev
ARG CLI_REF=tinybrains/cli:dev
ARG RUST_VERSION=1.98.1
# 0.5.4 is what this book is written against, and the musl builds are the only ones published
# for both architectures -- there is no aarch64-unknown-linux-gnu asset.
ARG MDBOOK_VERSION=0.5.4
ARG BUSYBOX_VERSION=1.37-musl

FROM ${ANTS_REF} AS ants
FROM ${CLI_REF} AS cli

# ---- the lesson replays, and the viewer that plays them -----------------------
#
# Trixie rather than bookworm. The reason was `ort`'s prebuilt onnxruntime wanting a newer
# libstdc++; the CLI links `tract` now, which is pure Rust and would run on anything, and this stays
# because the CLI's own image is trixie-based and moving a base is a change both make in step.
# python3 for make-map.py and the digest check.
FROM rust:${RUST_VERSION}-trixie AS lessons
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=cli /artifacts/bin/tinybrains /usr/local/bin/tinybrains

# The cartridge, laid out the way a `path` entry in a games registry expects: the component by
# extension, cartridge.json beside it, maps/ under it. `tinybrains` knows no game -- it resolves one
# from a registry -- so this is the registry, written here rather than borrowed from devops.
COPY --from=ants /artifacts/ /cartridge/ants/
RUN printf '[games.ants]\nname = "Ants"\npath = "/cartridge/ants"\n' > /cartridge/registry.toml
ENV TINYBRAINS_REGISTRY=/cartridge/registry.toml

WORKDIR /src
COPY tutorials/ ./tutorials/
# The viewer where build.sh looks for it: it copies from ${ANTS_DIR}/viz/dist.
COPY --from=ants /artifacts/viz/ /cartridge/ants-viz/viz/dist/
ENV ANTS_DIR=/cartridge/ants-viz

RUN mkdir -p src && tutorials/build.sh

# ---- the book ----------------------------------------------------------------
FROM rust:${RUST_VERSION}-trixie AS book
ARG MDBOOK_VERSION
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) arch=x86_64-unknown-linux-musl ;; \
      arm64) arch=aarch64-unknown-linux-musl ;; \
      *) echo "no mdbook build for ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/rust-lang/mdBook/releases/download/v${MDBOOK_VERSION}/mdbook-v${MDBOOK_VERSION}-${arch}.tar.gz" \
      | tar -xz -C /usr/local/bin; \
    mdbook --version

WORKDIR /src
COPY . .
# `create-missing = false`: a SUMMARY entry with no file is an error, so the generated pages have to
# be in place before mdbook runs.
COPY --from=lessons /src/src/tutorials/ ./src/tutorials/
COPY --from=lessons /src/src/viz/       ./src/viz/
RUN mdbook build

# ---- the carrier -------------------------------------------------------------
FROM busybox:${BUSYBOX_VERSION}
LABEL org.opencontainers.image.title="TinyBrains competitor guide" \
      org.opencontainers.image.source="https://github.com/Tiny-Brains/docs" \
      org.opencontainers.image.description="the mdBook competitor guide, rendered"

COPY --from=book /src/book/ /artifacts/book/

# `docker run --rm -v docs-book:/out tinybrains/docs:dev` populates a volume with the rendered book.
CMD ["sh", "-c", "cp -a /artifacts/. /out/"]
