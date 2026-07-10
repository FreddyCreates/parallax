FROM rust:1.78-alpine AS builder

RUN apk add --no-cache musl-dev
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release && rm -rf src
COPY src ./src
RUN cargo build --release

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/target/release/parralax-rust-engine /usr/local/bin/parralax-rust-engine

EXPOSE 8083
ENTRYPOINT ["parralax-rust-engine"]
