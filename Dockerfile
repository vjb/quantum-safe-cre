# Phase 1: Builder Layer
# Use Rust latest to support Rust 2024 edition requirements in dependencies
FROM rust:bookworm AS builder

# Install system dependencies required by SP1 and cryptographic crates
RUN apt-get update && apt-get install -y clang cmake build-essential curl pkg-config libssl-dev protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install Docker CLI natively to bypass archaic Debian repository version mismatches
RUN curl -fsSL -O https://download.docker.com/linux/static/stable/x86_64/docker-26.0.0.tgz && \
    tar xzvf docker-26.0.0.tgz && \
    cp docker/docker /usr/local/bin/ && \
    chmod +x /usr/local/bin/docker && \
    rm -rf docker docker-26.0.0.tgz

# Install SP1 toolchain and CLI
RUN curl -L https://sp1.succinct.xyz | bash
ENV PATH="/root/.sp1/bin:${PATH}"
# Cryptographically pin the CLI version
RUN sp1up -v v6.0.2

# Set up project workspace
WORKDIR /app
COPY . .

# Run the `1-client` to guarantee `intent.json` is physically generated
WORKDIR /app/1-client
RUN cargo run

# Pre-compile the SP1 guest program natively using cargo-prove
WORKDIR /app/2-sp1-coprocessor/program
RUN cargo prove build && \
    mkdir -p /app/elf && \
    cp $(find /app/2-sp1-coprocessor/target/elf-compilation -name "program" -type f | head -n 1) /app/elf/program

# Execute the STARK ZK-Coprocessor 
WORKDIR /app/2-sp1-coprocessor/script
RUN rm build.rs

# Supply ELF path statically for Rust compilation macro
ENV SP1_PROGRAM_ELF="/app/elf/program"

# Build release profile with CUDA support
RUN cargo build --release --features cuda

# Phase 2: Lightweight Runtime Enclave
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

# Install base dynamic execution wrappers necessary for Cargo binaries interacting with Google Storage APIs
RUN apt-get update && apt-get install -y curl pkg-config libssl3 ca-certificates curl gnupg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y google-cloud-cli && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app/2-sp1-coprocessor/script
COPY --from=builder /app/1-client/intent.json /app/1-client/intent.json
COPY --from=builder /app/elf/program /app/elf/program
COPY --from=builder /app/2-sp1-coprocessor/target/release/script /usr/local/bin/zkvm-script

ENV RUST_LOG="info"
ENV SP1_PROGRAM_ELF="/app/elf/program"
ENV SP1_PROVER="cuda"

CMD ["zkvm-script"]
