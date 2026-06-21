FROM alpine:edge

RUN apk add --no-cache \
    build-base cmake ninja pkgconf automake autoconf libtool \
    rust cargo go \
    python3 py3-pip python3-dev \
    bash zsh fish tmux screen \
    vim neovim nano less \
    curl wget ca-certificates openssh sshpass rsync socat nmap \
    ripgrep fd fzf tree eza bat unzip zip tar gzip bzip2 xz zstd \
    htop btop iotop iftop \
    git git-lfs lazygit \
    docker-cli docker-cli-compose \
    podman podman-docker fuse-overlayfs slirp4netns shadow \
    jq yq httpie shellcheck shfmt make direnv starship \
    tzdata nix ruby ruby-dev openjdk17 tidyhtml libxml2-utils \
    nodejs npm \
    binwalk zmap masscan \
    && cp /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "UTC" > /etc/timezone

# Install uv system-wide
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/ \
    && mv /root/.local/bin/uvx /usr/local/bin/

# Setup user
RUN addgroup -g 1000 -S user \
 && adduser -u 1000 -S -G user -s /bin/bash -h /home/user user \
 && echo "user:100000:65536" >> /etc/subuid \
 && echo "user:100000:65536" >> /etc/subgid \
 && mkdir -p /etc/nix /home/user/.local/bin \
 && printf "max-jobs = 4\nextra-experimental-features = nix-command flakes\n" > /etc/nix/nix.conf \
 && chown -R user:user /home/user

# Install npm packages globally (as root)
RUN npm install -g yarn pnpm typescript ts-node prettier eslint

USER user
WORKDIR /home/user

ENV HOME=/home/user \
    SHELL=/bin/bash \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    PATH="/home/user/.local/bin:/home/user/.bun/bin:/home/user/go/bin:$PATH"

# Install bun, Python tools, Ruby gem, and recon tools as user
RUN curl -fsSL https://bun.sh/install | bash \
    && uv tool install black \
    && uv tool install yapf \
    && uv tool install isort \
    && uv tool install flake8 \
    && uv tool install mypy \
    && uv tool install sublist3r \
    && gem install rubocop

# Shell config
RUN printf 'export BUN_INSTALL="$HOME/.bun"\n\
export PATH="$BUN_INSTALL/bin:$PATH"\n\
export GOPATH="$HOME/go"\n\
export PATH="$GOPATH/bin:$PATH"\n\
eval "$(starship init bash)"\n\
eval "$(direnv hook bash)"\n' > "$HOME/.bashrc" \
    && sed 's/bash/zsh/g; s/init bash/init zsh/; s/hook bash/hook zsh/g' "$HOME/.bashrc" > "$HOME/.zshrc"

CMD ["sleep", "infinity"]
