FROM debian:stable-slim

LABEL maintainer "statiolake <satiolake@gmail.com>"

# 最低限のツールをまずはインストール
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        zsh \
        tmux \
        git \
        python3 \
        python3-pip \
        python3-venv \
        python-is-python3 \
        curl \
        locales \
    && rm -rf /var/cache/apk/*

# 言語を変更
RUN echo "C.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LANG C.UTF-8

# Neovim をインストール (ビルド)
RUN apt-get install -y \
    ninja-build \
    gettext \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    cmake \
    g++ pkg-config \
    unzip \
    curl \
    doxygen \
    && rm -rf /var/cache/apk/*

RUN cd /tmp && \
    git clone https://github.com/neovim/neovim --depth 1 && \
    cd neovim && \
    make CMAKE_BUILD_TYPE=RelWithDebInfo && \
    make install
# RUN curl -L https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz \
# #RUN curl -L https://github.com/neovim/neovim/releases/download/v0.6.1/nvim-linux64.tar.gz \
#   > /tmp/nvim-linux64.tar.gz && \
#   tar xvzf /tmp/nvim-linux64.tar.gz --overwrite --strip-components=1 -C /usr

# Neovim <-> Python プラグインをインストール
RUN pip3 install --upgrade pip pynvim

# certifi (証明書的なやつ) をインストール
RUN pip3 install certifi

# Vim をインストール (ビルド)
RUN apt-get install -y \
      build-essential \
      gettext \
      libtinfo-dev \
      libacl1-dev \
      libgpm-dev \
      python3-dev \
      luajit \
      libluajit-5.1-2 \
      libluajit-5.1-dev \
      && rm -rf /var/cache/apk/*

RUN cd /tmp && \
    git clone https://github.com/vim/vim --depth 1 && \
    cd vim/src && \
    ./configure --with-features=huge --disable-gui \
      --enable-fail-if-missing \
      --enable-python3interp \
      --enable-luainterp --with-luajit \
    && \
    make && \
    make install

# 設定をインストール
COPY . /root/dotfiles

# /root/dotfiles のすべてのファイルにおいて CRLF を LF にする
RUN find /root/dotfiles -type f -exec sed -i -e 's/\r$//g' {} \;

# /root/dotfiles のすべてのファイルからオーナー以外の書き込み権限を消す
# (zsh の compinit が insecure directories というので)
RUN chmod -R go-w /root/dotfiles

# tmux の prefix key を M-q にする (ホストとかぶらないようにするため)
RUN sed -i -e 's/C-q/M-q/g' /root/dotfiles/tmux.conf

RUN python3 /root/dotfiles/install.py

# 初期ディレクトリを指定
WORKDIR /root

# ログインシェルを zsh に変更
RUN chsh -s /usr/bin/zsh

# 設定ファイルを他からボリュームとしてマウントできるようにする
VOLUME ["/root/dotfiles", "/root/.dotfiles_standalone_deno", "/root/.dotfiles_standalone_node", "/root/.config/nvim", "/root/.local/share/nvim"]

ENTRYPOINT ["/usr/bin/zsh"]
