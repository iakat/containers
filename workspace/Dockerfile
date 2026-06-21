FROM alpine:edge

# Cleanup scripts (golfed, opportunistic rm -rf)
RUN printf 'cleanup(){ rm -rf /var/cache/apk/* /tmp/* /root/.cache /root/.local /root/.npm /root/.cargo /usr/local/bin/cleanup*.sh; }\ncleanup-user(){ rm -rf /tmp/* "$HOME/.cache" "$HOME/.cargo" "$HOME/.gem" "$HOME/go/pkg" "$HOME/.local/share/uv/cache" "$HOME"/.*-install; }\n' >/etc/cleanup && . /etc/cleanup && cleanup

# System packages
RUN apk add --no-cache build-base cmake ninja pkgconf automake autoconf libtool rust cargo go python3 py3-pip python3-dev bash zsh fish tmux screen vim neovim nano less curl wget ca-certificates openssh sshpass rsync socat nmap ripgrep fd fzf tree eza bat unzip zip tar gzip bzip2 xz zstd htop btop iotop iftop git git-lfs lazygit docker-cli docker-cli-compose podman podman-docker fuse-overlayfs slirp4netns shadow jq yq httpie shellcheck shfmt make direnv starship tzdata nix ruby ruby-dev openjdk17 tidyhtml libxml2-utils nodejs npm zmap masscan binutils \
    && cp /usr/share/zoneinfo/UTC /etc/localtime && echo "UTC" > /etc/timezone \
    && . /etc/cleanup && cleanup

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && mv /root/.local/bin/uv* /usr/local/bin/ && . /etc/cleanup && cleanup

# User setup
RUN addgroup -g 1000 -S user && adduser -u 1000 -S -G user -s /bin/bash -h /home/user user && echo "user:100000:65536" >>/etc/subuid && echo "user:100000:65536" >>/etc/subgid && mkdir -p /etc/nix && printf "max-jobs = 4\nextra-experimental-features = nix-command flakes\n" >/etc/nix/nix.conf && chown user:user /home/user && . /etc/cleanup && cleanup

# npm
RUN npm install -g yarn pnpm typescript ts-node prettier eslint && npm cache clean --force --loglevel=error && . /etc/cleanup && cleanup

USER user
WORKDIR /home/user

ENV HOME=/home/user SHELL=/bin/bash LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=xterm-256color PATH="/home/user/.local/bin:/home/user/.bun/bin:/home/user/go/bin:$PATH" GOPATH="/home/user/go" GOCACHE=/tmp/go-cache GOMODCACHE=/tmp/go-mod UV_CACHE_DIR=/tmp/uv-cache NIX_PROFILES="/nix/var/nix/profiles/default /home/user/.nix-profile"

# Nix profile
RUN mkdir -p /home/user/.nix-profile && printf '. "$HOME/.nix-profile/etc/profile.d/nix.sh"\nexport PATH="$HOME/.nix-profile/bin:$PATH"\n' >>"$HOME/.bashrc" && cp "$HOME/.bashrc" "$HOME/.zshrc" && sed -i 's/bash/zsh/g; s/init bash/init zsh/; s/hook bash/hook zsh/g' "$HOME/.zshrc"

# User tools
RUN curl -fsSL https://bun.sh/install | bash && uv tool install black yapf isort flake8 mypy binwalk sublist3r && go install -ldflags="-s -w" github.com/projectdiscovery/httpx/cmd/httpx@latest github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest github.com/ffuf/ffuf/v2@latest && gem install rubocop && gem cleanup -q 2>/dev/null || . /etc/cleanup && cleanup-user

# Shell config (final)
RUN printf 'export BUN_INSTALL="$HOME/.bun"\nexport PATH="$BUN_INSTALL/bin:$PATH"\nexport GOPATH="$HOME/go"\nexport PATH="$GOPATH/bin:$PATH"\neval "$(starship init bash)"\neval "$(direnv hook bash)"\n' >>"$HOME/.bashrc" && sed 's/bash/zsh/g; s/init bash/init zsh/; s/hook bash/hook zsh/g' "$HOME/.bashrc" >>"$HOME/.zshrc"

CMD ["sleep", "infinity"]
