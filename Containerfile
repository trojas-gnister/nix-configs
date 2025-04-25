FROM docker.io/debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    CARGO_HOME=/opt/rust/cargo \
    RUSTUP_HOME=/opt/rust/rustup \
    GOPATH=/go \
    NVM_DIR=/opt/nvm \
    NODE_VERSION=20.12.2 \
    GO_VERSION=1.22.2 \
    PATH=/opt/rust/cargo/bin:/usr/local/go/bin:/opt/nvm/versions/node/v20.12.2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN mkdir -p /opt/rust /opt/neovim /usr/local/go /go /opt/nvm /workspace

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git gnupg libfuse2 \
      lsb-release procps python3 python3-pip unzip wget xz-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm use $NODE_VERSION && \
    nvm alias default $NODE_VERSION

RUN npm install -g typescript

RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable

RUN curl -fL https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.appimage -o /opt/neovim/nvim.appimage && \
    chmod +x /opt/neovim/nvim.appimage && \
    ln -s /opt/neovim/nvim.appimage /usr/local/bin/nvim


WORKDIR /workspace
CMD ["sleep", "infinity"]
