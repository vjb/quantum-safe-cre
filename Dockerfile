# Use Rust latest to support Rust 2024 edition requirements in dependencies
FROM rust:bookworm

# Install system dependencies required by SP1 and cryptographic crates
RUN apt-get update && apt-get install -y clang cmake build-essential curl pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

# Install SP1 toolchain and CLI
RUN curl -L https://sp1.succinct.xyz | bash
ENV PATH="/root/.sp1/bin:${PATH}"
RUN sp1up

# Fix SP1 'cargo' custom toolchain propagation bug in Docker.
# Succinct's sp1up installs a custom toolchain to ~/.rustup, but rust:bookworm uses /usr/local/rustup.
RUN ln -s /root/.rustup/toolchains/* /usr/local/rustup/toolchains/ 2>/dev/null || true
RUN for chain in /usr/local/rustup/toolchains/*; do cp /usr/local/cargo/bin/cargo "$chain/bin/cargo" 2>/dev/null || true; done

# Set up project workspace
WORKDIR /app
COPY . .

# Phase 1: Run the `1-client` to guarantee `intent.json` is physically generated
WORKDIR /app/1-client
RUN cargo run

# Phase 2: Execute the STARK ZK-Coprocessor 
# Executing inside the Linux container completely isolates the process from Windows NTFS file locking collisions (error 32)
WORKDIR /app/2-sp1-coprocessor/script
ENV RUST_LOG="info"
CMD ["cargo", "run", "--release"]
