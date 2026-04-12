FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y curl git build-essential unzip wget ca-certificates gnupg xz-utils && rm -rf /var/lib/apt/lists/*

# Node.js 20 LTS (Required for @chainlink/cre-sdk)
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs

# Bun (Required for CRE CLI TypeScript compilation logic)
ENV BUN_INSTALL="/root/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"
RUN curl -fsSL https://bun.sh/install | bash

# Chainlink CRE CLI & Javy WASM Compiler
RUN curl -sSL https://cre.chain.link/install.sh | bash && mv /root/.cre/bin/cre /usr/local/bin/cre
RUN mkdir -p /root/.cache/javy/v5.0.4/linux-x64 \
    && curl -L https://github.com/bytecodealliance/javy/releases/download/v5.0.4/javy-x86_64-linux-v5.0.4.gz | gunzip > /root/.cache/javy/v5.0.4/linux-x64/javy \
    && chmod +x /root/.cache/javy/v5.0.4/linux-x64/javy

WORKDIR /app
COPY . .

# Direct local state mapping consumes node_modules physically. No restricted network access required.
CMD ["cre", "workflow", "simulate", "."]
