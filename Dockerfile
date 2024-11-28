# Step 1: Use Rust 1.82 as the builder environment
FROM rust:1.82 AS builder

# Set working directory
WORKDIR /flowgger

# Copy source files
COPY . .

# Install necessary dependencies and build the project
RUN apt-get update && \
    apt-get install -y capnproto libssl-dev pkg-config && \
    rustup target add aarch64-unknown-linux-gnu && \
    cargo build --release --target=aarch64-unknown-linux-gnu && \
    strip target/aarch64-unknown-linux-gnu#/release/flowgger


# Step 2: Use Ubuntu 22.04 as the runtime environment
#FROM ubuntu:22.04
#LABEL maintainer="Frank Denis, Damian Czaja <trojan295@gmail.com>"

FROM alpine:latest
LABEL maintainer="Russell Hurren <russell@zeropointnetworks.com>"

# Set working directory for runtime
WORKDIR /opt/flowgger

# Install OpenSSL 3 and other runtime dependencies
#RUN apt-get update && \
#    apt-get install -y libssl3 && \
#    rm -rf /var/lib/apt/lists/*

RUN apk add --no-cache libssl3

# Copy the built Flowgger binary from the builder stage
COPY --from=builder /flowgger/target/aarch64-unknown-linux-musl/release/flowgger /opt/flowgger/bin/flowgger

# Copy the configuration file and entrypoint script
COPY flowgger.toml /opt/flowgger/etc/flowgger.toml
COPY entrypoint.sh /

# Ensure entrypoint script has execute permissions
RUN chmod +x /entrypoint.sh

# Expose default ports for Syslog and IPFIX
EXPOSE 514/udp 4730/udp

# Define the entrypoint and command for the container
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/flowgger/etc/flowgger.toml"]
