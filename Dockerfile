# syntax=docker/dockerfile:1.2
FROM rust:slim-bullseye AS builder

RUN apt-get update && apt-get install --no-install-recommends -y pkg-config libssl-dev

WORKDIR /liq-bot

COPY node_modules node_modules
COPY Cargo.lock .
COPY Cargo.toml .
COPY deployments deployments
COPY src src
COPY lib lib

RUN rustup component add rustfmt
RUN rustup component add clippy

RUN cargo fmt --check
RUN cargo clippy -- -D warnings
RUN cargo build --release

FROM debian:stable-slim

RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /liq-bot

COPY --from=builder /liq-bot/target/release/liq-bot .
COPY --from=builder /liq-bot/deployments deployments
COPY --from=builder /liq-bot/node_modules/@exactly-protocol/protocol/deployments node_modules/@exactly-protocol/protocol/deployments

ENTRYPOINT [ "/liq-bot/liq-bot" ]
