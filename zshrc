##########################################################################################
# 環境判定
##########################################################################################
if uname -a | grep WSL > /dev/null; then
    IS_WSL=1
else
    IS_WSL=0
fi

if uname -a | grep Darwin > /dev/null; then
    IS_MACOS=1
else
    IS_MACOS=0
fi

##########################################################################################
# macOS では homebrew を有効化する
##########################################################################################
if [[ $IS_MACOS == 1 ]]; then
    export PATH=$PATH:/opt/homebrew/bin
fi

##########################################################################################
# 基本設定
##########################################################################################
# tmux を起動する
if \
    which tmux > /dev/null \
    && [[ -z "$DISABLE_TMUX" ]] \
    && [[ -z "$TMUX" ]]; then
    if tmux ls > /dev/null; then
        # もし tmux のセッションがすでに存在するならそちらへ attach
        exec tmux a
    else
        # 新しいセッションを作成する
        exec tmux
    fi
fi

# FPATH
export FPATH="${HOME}/.zsh/functions:${FPATH}"

# Ctrl+S で `stop` するのを解除
stty stop undef

# setopt correct                           # タイプミスの修正
setopt share_history                     # 履歴をほかの zsh と共有する
setopt extendedglob                      # 拡張された glob を有効にする
autoload -U promptinit                   # プロンプトのテーマを利用できるようにする
promptinit                               # 初期化
export PROMPT="%B%*%b %B%F{green}%n@%M%f%b:%B%F{blue}%~%f%b
(%(?.'-'.-_-))/ %# "                     # シンプルな自作プロンプト (ちょっとかわいい)
if cat /.dockerenv > /dev/null 2>&1; then
    # Docker なのでそれとわかるようにプロンプトを変える
    export PROMPT="%B%F{black}(docker)%f%b ${PROMPT}"
fi

# Emacs キーバインディング
bindkey -e

autoload -U compinit                     # zsh の強力な補完機能を利用できるようにする
compinit                                 # 初期化
# 補完の設定
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
compdef hub=git

# Shell Theming
# [ -n "$PS1" ] && sh ~/.nightshell/office-dark
# eval `dircolors ~/.nightshell/dircolors`

# Environmental Variables / Aliases
source ~/.envvars                        # 環境変数
source ~/.zsh_aliases                    # エイリアス

# FPATH
export MANPATH="$MANPATH:/usr/local/texlive/2018/texmf-dist/doc/man"
export INFOPATH="$INFOPATH:/usr/local/texlive/2018/texmf-dist/doc/info"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
if which pyenv > /dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

# elementary OS のみ - プロセス完了時の通知を ON にする
if which lsb_release > /dev/null 2>&1 && [[ "$(lsb_release -is)" == "elementary" ]]; then
    builtin . /usr/share/io.elementary.terminal/enable-zsh-completion-notifications || builtin true
fi

PERIOD=5

# WSL 固有の設定
if [[ $IS_WSL == 1 ]]; then
    # X11 (WSLg) の設定
    #setxkbmap jp
    #which xrdb > /dev/null && xrdb ~/.Xresources

    # XDG_RUNTIME_DIR 等の設定
    loginctl enable-linger $USER

    # 毎プロンプトごとに時刻を同期
    autoload -Uz add-zsh-hook
    function periodic_fixtime() {
        if [[ ! -e "/.dockerenv" ]]; then
            # docker 環境内では無効化する
            fixtime -n
        fi
    }
    add-zsh-hook periodic periodic_fixtime

    # WSLg を使わない場合は GWSL のための設定を仕込む。
    # 適当に /mnt/wslg に常にありそうな PulseServer を確認する
    # 本当は mount とか確認したらいいのかもしれないが...
    #
    # Docker 環境など、既に $DISPLAY が外から設定されている場合は何もしない。
    if [[ -z "$DISPLAY" ]] && [[ ! -e "/mnt/wslg/PulseServer" ]]; then
        host_ip="$(ip route | grep 'default via' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
        export DISPLAY="${host_ip}:0.0"
        export PULSE_SERVER="tcp:${host_ip}"
    fi
fi

# 履歴
export HISTFILE=${HOME}/.zsh_history     # 履歴ファイルの保存先
export HISTSIZE=1000                     # メモリに保存される履歴の件数
export SAVEHIST=1000000                  # 履歴ファイルに保存される履歴の件数

##########################################################################################
# Functions
##########################################################################################
source ~/.zsh/functions/clear-screen-rehash
autoload -U edit-vimrc-file
autoload -U edit-emacsd-file
autoload -U change-font-profile

if ! [[ -z "$WORK_DIR" ]]; then
    cd "$WORK_DIR"
fi

##########################################################################################
# 環境固有設定
##########################################################################################
if [[ -e /usr/share/nvm/init-nvm.sh ]]; then
    source /usr/share/nvm/init-nvm.sh
fi

if [[ -e ~/setup-proxy.sh ]]; then
    source ~/setup-proxy.sh
fi
