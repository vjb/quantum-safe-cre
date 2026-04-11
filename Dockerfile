# Use Rust latest to support Rust 2024 edition requirements in dependencies
FROM rust:bookworm

# Install system dependencies required by SP1 and cryptographic crates
RUN apt-get update && apt-get install -y clang cmake build-essential curl pkg-config libssl-dev protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install Docker CLI natively to bypass archaic Debian repository version mismatches (API 1.41 vs host 1.44)
RUN curl -fsSL -O https://download.docker.com/linux/static/stable/x86_64/docker-26.0.0.tgz && \
    tar xzvf docker-26.0.0.tgz && \
    cp docker/docker /usr/local/bin/ && \
    chmod +x /usr/local/bin/docker && \
    rm -rf docker docker-26.0.0.tgz

# Install SP1 toolchain and CLI
RUN curl -L https://sp1.succinct.xyz | bash
ENV PATH="/root/.sp1/bin:${PATH}"
# Cryptographically pin the CLI version to guarantee ELF geometric parity with SP1 SDK 6.0.2
RUN sp1up -v v6.0.2

# Set up project workspace
WORKDIR /app
COPY . .

# Phase 1: Run the `1-client` to guarantee `intent.json` is physically generated
WORKDIR /app/1-client
RUN cargo run

# Pre-compile the SP1 guest program natively using cargo-prove to completely bypass rustup proxy bugs
WORKDIR /app/2-sp1-coprocessor/program
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    cargo prove build && \
    mkdir -p /app/elf && \
    cp $(find /app/2-sp1-coprocessor/target/elf-compilation -name "program" -type f | head -n 1) /app/elf/program

# Phase 2: Execute the STARK ZK-Coprocessor 
# Executing inside the Linux container completely isolates the process from Windows NTFS file locking collisions (error 32)
WORKDIR /app/2-sp1-coprocessor/script
ENV RUST_LOG="info"
ENV SP1_PROGRAM_ELF="/app/elf/program"

# Delete build.rs to permanently bypass the SP1 Rustup interceptor bug
RUN rm build.rs

# Enable BuildKit caching for the cargo registry and build target
# This prevents Docker from recompiling the entire SP1 universe if you change 1 line of code.
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/2-sp1-coprocessor/target \
    cargo build --release && \
    cp /app/2-sp1-coprocessor/target/release/script /usr/local/bin/zkvm-script

CMD ["zkvm-script"]
