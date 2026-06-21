FROM alpine:edge

RUN apk add --no-cache \
        build-base cmake ninja pkgconf automake autoconf libtool \
        rust cargo go \
        python3 py3-pip python3-dev py3-virtualenv \
        bash zsh fish tmux screen \
        vim neovim nano less \
        curl wget ca-certificates openssh sshpass rsync socat nmap \
        ripgrep fd fzf tree eza bat unzip zip tar gzip bzip2 xz zstd \
        htop btop iotop iftop nvtop \
        git git-lfs lazygit gh \
        docker-cli docker-cli-compose \
        podman podman-docker fuse-overlayfs slirp4netns uidmap shadow \
        jq yq httpie shellcheck shfmt make direnv starship \
        tzdata \
        nix \
        ruby ruby-dev openjdk17 scala \
        tidyhtml libxml2-utils htmlhint \
    && cp /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "UTC" > /etc/timezone

RUN addgroup -g 1000 -S user \
 && adduser -u 1000 -S -G user -s /bin/bash -h /home/user user \
 && mkdir -p /home/user/.local/bin /home/user/.cache \
 && chown -R user:user /home/user

# Rootless podman requires subuid/subgid mapping
RUN echo "user:100000:65536" >> /etc/subuid \
 && echo "user:100000:65536" >> /etc/subgid

RUN addgroup nixbld \
 && for i in $(seq 1 4); do adduser -S -D -H -G nixbld nixbld$i; done \
 && mkdir -p /etc/nix \
 && printf "allowed-users = @nix\nbuild-users-group = nixbld\nmax-jobs = 4\nextra-experimental-features = nix-command flakes\n" > /etc/nix/nix.conf \
 && printf '#!/sbin/openrc-run\ndescription="Nix daemon"\ncommand="/usr/sbin/nix-daemon"\ncommand_background="yes"\npidfile="/run/nix-daemon.pid"\n' > /etc/init.d/nix-daemon \
 && chmod +x /etc/init.d/nix-daemon \
 && rc-update add nix-daemon default

RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
 && mv /root/.local/bin/uv /usr/local/bin/uv \
 && mv /root/.local/bin/uvx /usr/local/bin/uvx

USER user
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash \
 && . "$HOME/.nvm/nvm.sh" \
 && nvm install --lts \
 && nvm alias default lts/* \
 && nvm use default \
 && npm install -g npm@latest yarn pnpm typescript ts-node prettier eslint \
 && curl -fsSL https://bun.sh/install | bash

USER root
RUN pip install --no-cache-dir --break-system-packages black yapf isort flake8 mypy \
 && gem install rubocop

RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/user/.bashrc \
 && echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> /home/user/.bashrc \
 && echo 'export BUN_INSTALL="$HOME/.bun"' >> /home/user/.bashrc \
 && echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> /home/user/.bashrc \
 && echo 'export GOPATH="$HOME/go"' >> /home/user/.bashrc \
 && echo 'export PATH="$GOPATH/bin:$PATH"' >> /home/user/.bashrc \
 && echo 'eval "$(starship init bash)"' >> /home/user/.bashrc \
 && echo 'eval "$(direnv hook bash)"' >> /home/user/.bashrc \
 && cp /home/user/.bashrc /home/user/.zshrc \
 && sed -i 's/bash/zsh/g' /home/user/.zshrc \
 && echo 'eval "$(starship init zsh)"' >> /home/user/.zshrc \
 && echo 'eval "$(direnv hook zsh)"' >> /home/user/.zshrc \
 && chown -R user:user /home/user

USER user
WORKDIR /home/user
ENV HOME=/home/user \
    SHELL=/bin/bash \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    PATH=/home/user/.local/bin:/home/user/.bun/bin:/home/user/go/bin:$PATH

CMD ["sleep", "infinity"]
