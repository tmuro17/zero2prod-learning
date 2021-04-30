FROM lukemathwalker/cargo-chef as planner
WORKDIR app
COPY ../../Desktop/zero-to-production-root-chapter05 .
# Compute a lock-like file for our project
RUN cargo chef prepare  --recipe-path recipe.json

FROM lukemathwalker/cargo-chef as planner
WORKDIR app
COPY --from=planner /app/recipe.json recipe.json
# Build our project dependencies, not our application!
RUN cargo chef cook --release --recipe-path recipe.json

FROM rust:1.50 AS builder
WORKDIR app
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
COPY ../../Desktop/zero-to-production-root-chapter05 .
# Build our application, leveraging the cached deps!
ENV SQLX_OFFLINE true
RUN cargo build --release --bin zero2prod

FROM debian:buster-slim AS runtime
WORKDIR app
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/zero2prod zero2prod
COPY ../../Desktop/zero-to-production-root-chapter05/configuration configuration
ENV APP_ENVIRONMENT production
ENTRYPOINT ["./zero2prod"]
