#!/usr/bin/env python
# -*- coding: utf-8 -*-
import enum
import gzip
import io
import os
import shutil
import ssl
import stat
import subprocess
import tempfile
import urllib.request
import zipfile
from pathlib import Path
from sys import argv, stderr

# ============================================================================
# Config
# ============================================================================
NODE_VERSION = "16.14.0"

ARROW = "=>"
SUBARROW = "-->"


# ============================================================================
# Helpers
# ============================================================================
def is_linux_musl():
    # musl かどうかは /bin/ls のライブラリを見て考慮することにする
    # TODO: より安全で絶対ありそうなファイルは？
    stddlls = subprocess.check_output(["ldd", "/bin/ls"]).decode("utf-8")
    return "musl" in stddlls


class Platform(enum.Enum):
    WINDOWS = enum.auto()
    LINUX_GLIBC = enum.auto()
    LINUX_MUSL = enum.auto()

    @staticmethod
    def detect():
        if os.name == "nt":
            return Platform.WINDOWS
        if is_linux_musl():
            return Platform.LINUX_MUSL
        return Platform.LINUX_GLIBC


ENV = Platform.detect()
print(f"detected environment: {ENV}", file=stderr)

if ENV == Platform.WINDOWS:
    import _winapi


class Directories:
    class Source:
        def __init__(self):
            self.base = Path(__file__).parent.absolute()
            self.git = self.base / "git"
            self.neovim_old = self.base / "neovim-old"
            self.neovim = self.base / "neovim"

    class Target:
        def __init__(self):
            self.home = Directories.envvar("HOME") or Directories.envvar(
                "USERPROFILE"
            )
            self.bin = self.home / "bin"
            # TODO: XDG_CONFIG_HOME
            self.config = self.home / ".config"
            self.nvimfiles_old, self.nvimdata_old = self._get_nvimfiles(
                "nvim-old"
            )
            self.nvimfiles, self.nvimdata = self._get_nvimfiles("nvim")
            if ENV == Platform.WINDOWS:
                self.pwshprofiles = self._get_pwshprofiles()

        def _get_nvimfiles(self, appname="nvim"):
            if ENV == Platform.WINDOWS:
                localappdata = Directories.envvar("LOCALAPPDATA")
                return (
                    localappdata / appname,
                    localappdata / f"{appname}-data",
                )
            else:
                # TODO: $XDG_CONFIG_HOME を使うべき
                return (
                    self.home / ".config" / appname,
                    self.home / ".local" / "share" / appname,
                )

        def _get_pwshprofiles(self):
            # TODO: Get Document folder using appropriate API
            prof_paths = []

            userprofile = Directories.envvar("USERPROFILE")

            documents = userprofile / "Documents"
            if documents.exists():
                prof_paths.append(documents / "WindowsPowerShell")
                prof_paths.append(documents / "PowerShell")

            onedrive_documents = userprofile / "OneDrive" / "ドキュメント"
            if onedrive_documents.exists():
                prof_paths.append(onedrive_documents / "WindowsPowerShell")
                prof_paths.append(onedrive_documents / "PowerShell")

            return prof_paths

    def __init__(self):
        echo("Determining folders...", ARROW)

        self.s = Directories.Source()
        self.t = Directories.Target()

        for name, value in vars(self.s).items():
            echo(f"s.{name}: {value}", "-->")
        for name, value in vars(self.t).items():
            echo(f"t.{name}: {value}", "-->")

    @staticmethod
    def envvar(envvar):
        path = os.getenv(envvar)
        if not path:
            raise RuntimeError(f"environment variable {envvar} is not set")
        return Path(path)


def remove_all(path):
    def force_remove_readonly(_action, path, _exc):
        os.chmod(path, stat.S_IWRITE)
        os.remove(path)

    if not Path(path).exists():
        return
    shutil.rmtree(path, onerror=force_remove_readonly)


def is_link(path):
    path = Path(path)
    if path.is_symlink():
        return True
    try:
        return bool(os.readlink(path))
    except OSError:
        return False


def ensure_link_not_exist(path, *, silent):
    path = Path(path)
    if not path.exists():
        return

    # If it is link already, remove it.
    if is_link(path):
        os.remove(path)
        if path.exists():
            raise RuntimeError(f"failed to remove {path}")
        return

    # This is non-link file. Confirm it to user before removing.
    if not silent:
        yn = input(
            f"non-link file or entry already exists at {path}. would you like to remove?"
        )
        if yn == "y" or yn == "Y":
            os.remove(path)
            if path.exists():
                raise RuntimeError(f"failed to remove {path}")
            return

    raise RuntimeError(f"non-link file or entry already exists at {path}")


def echo(msg, arrow):
    """Echo progress message."""
    print(f"\033[1;34m{arrow} \033[1;39m{msg}\033[0;39m", file=stderr)


def linkf(src, dst, *, silent):
    """Create symlink for file."""
    ensure_link_not_exist(dst, silent=silent)
    os.symlink(src, dst, target_is_directory=False)


def linkd(src, dst, *, silent, should_symlink=False):
    """
    Create symlink for directory unless on Windows and not should_symlink.
    """
    ensure_link_not_exist(dst, silent=silent)
    if ENV != Platform.WINDOWS or should_symlink:
        os.symlink(src, dst, target_is_directory=True)
        return

    _winapi.CreateJunction(str(src), str(dst))


def mergef(src, dst, *, contents_order="src_then_dst"):
    with open(src, "r") as f:
        src_lines = f.readlines()
    try:
        with open(dst, "r") as f:
            dst_lines = f.readlines()
    except FileNotFoundError:
        dst_lines = []

    if contents_order == "src_then_dst":
        after_lines = src_lines + dst_lines
    elif contents_order == "dst_then_src":
        after_lines = dst_lines + src_lines
    else:
        raise RuntimeError(f"unknown contents order: {contents_order}")

    with open(dst, "w") as f:
        f.writelines(after_lines)


def git_clone(remote, local, *, force):
    if Path(local).exists():
        # force でないときはスキップ
        if not force:
            echo(f"{local} exists, skipping git clone.", SUBARROW)
            return
        remove_all(local)
    subprocess.check_output(["git", "clone", remote, local])


def download(url):
    # SSL エラーの回避のため、証明書を取得する
    # Windows では書き込みと同時に開けないので delete=False で作成して改めて開
    # き直す必要がある (ファイルは手動削除の必要がある)
    with tempfile.NamedTemporaryFile(delete=False) as cafile:
        cert = urllib.request.urlopen("https://mkcert.org/generate/").read()
        cafile.write(cert)

    try:
        context = ssl.create_default_context(cafile=cafile.name)
        return urllib.request.urlopen(url, context=context).read()
    finally:
        os.remove(cafile.name)


def ungzip(data):
    return gzip.decompress(data)


def unzip(data, fname):
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        return zf.read(fname)


def save_as(data, path):
    os.makedirs(Path(path).parent, exist_ok=True)
    with open(path, "wb") as out:
        out.write(data)


# ============================================================================
# Steps
# ============================================================================
def setup_git(d, silent):
    if ENV == Platform.WINDOWS:
        linkf(
            d.s.git / "gitconfig_windows",
            d.t.home / ".gitconfig",
            silent=silent,
        )
    else:
        linkf(
            d.s.git / "gitconfig_unix", d.t.home / ".gitconfig", silent=silent
        )

    if ENV == Platform.WINDOWS:
        linkf(
            d.s.git / "gitattributes_windows",
            d.t.home / ".gitattributes",
            silent=silent,
        )

    linkf(
        d.s.git / "gitignore_global",
        d.t.home / ".gitignore_global",
        silent=silent,
    )

    os.makedirs(d.t.config / "git", exist_ok=True)
    linkd(d.s.git / "hooks", d.t.config / "git" / "hooks", silent=silent)


def setup_neovim_appimage(d):
    # Neovim がインストールされていない場合だけ使う
    if ENV == Platform.WINDOWS or shutil.which("nvim") is not None:
        return

    url = "https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage"
    target_path = d.t.home / "nvim.appimage"
    save_as(download(url), target_path)
    subprocess.check_output(["chmod", "+x", d.t.home / "nvim.appimage"])


def install_node(d, *, force):
    target_path = d.t.home / ".dotfiles_standalone_node"
    if not force and Path(target_path).exists():
        echo(f"{target_path} exists, skipping.", SUBARROW)
        return

    url_base, stem, ext = None, None, None
    if ENV == Platform.WINDOWS:
        url_base = f"https://nodejs.org/dist/v{NODE_VERSION}"
        stem, ext = f"node-v{NODE_VERSION}-win-x64", ".zip"
    elif ENV == Platform.LINUX_GLIBC:
        url_base = f"https://nodejs.org/dist/v{NODE_VERSION}"
        stem, ext = f"node-v{NODE_VERSION}-linux-x64", ".tar.gz"
    elif ENV == Platform.LINUX_MUSL:
        url_base = f"https://unofficial-builds.nodejs.org/download/release/v{NODE_VERSION}/"
        stem, ext = f"node-v{NODE_VERSION}-linux-x64-musl", ".tar.gz"
    else:
        raise RuntimeError(f"Unknown platform {ENV}")

    archive = stem + ext
    url = f"{url_base}/{archive}"

    # Download it to the temporary file
    echo(f"Downloading NodeJS from {url} ...", SUBARROW)
    _, tmp_path = tempfile.mkstemp(suffix=ext)
    save_as(download(url), tmp_path)

    echo("Extracting NodeJS...", SUBARROW)
    # Unpack the archive into the temporary directory and then move the
    # content to the ~/.dotfiles_standalone_node.
    with tempfile.TemporaryDirectory() as tmp_dest_dir:
        tmp_dest_dir = Path(tmp_dest_dir)
        shutil.unpack_archive(tmp_path, tmp_dest_dir)
        remove_all(target_path)
        shutil.move(tmp_dest_dir / stem, target_path)


def install_deno(d, *, force):
    target_path = d.t.home / ".dotfiles_standalone_deno"
    if not force and Path(target_path).exists():
        echo(f"{target_path} exists, skipping.", SUBARROW)
        return

    exe = "deno.exe" if ENV == Platform.WINDOWS else "deno"
    target = (
        "x86_64-pc-windows-msvc"
        if ENV == Platform.WINDOWS
        else "x86_64-unknown-linux-gnu"
    )
    url = f"https://github.com/denoland/deno/releases/latest/download/deno-{target}.zip"
    echo(f"Downloading Deno from {url} ...", SUBARROW)
    os.makedirs(target_path, exist_ok=True)
    target_path_exe = target_path / exe
    save_as(unzip(download(url), exe), target_path_exe)
    os.chmod(target_path_exe, 0o755)


def setup_neovim(d, *, force, silent):
    echo("Making symlinks...", SUBARROW)
    os.makedirs(d.t.nvimfiles_old, exist_ok=True)
    os.makedirs(d.t.nvimdata_old, exist_ok=True)
    os.makedirs(d.t.nvimdata_old / "coc", exist_ok=True)
    os.makedirs(d.t.nvimfiles, exist_ok=True)
    linkf(
        d.s.neovim_old / "vimrc_vscode_neovim",
        d.t.home / ".vimrc_vscode_neovim",
        silent=silent,
    )
    linkf(
        d.s.neovim_old / "coc-settings.json",
        d.t.nvimfiles_old / "coc-settings.json",
        silent=silent,
    )
    linkd(d.s.neovim_old / "rtp", d.t.nvimfiles_old / "rtp", silent=silent)
    linkd(
        d.s.neovim_old / "ultisnips",
        d.t.nvimfiles_old / "ultisnips",
        silent=silent,
    )
    linkd(
        d.s.neovim_old / "ultisnips",
        d.t.nvimdata_old / "coc" / "ultisnips",
        silent=silent,
    )
    linkd(
        d.s.neovim_old / "vsnip", d.t.nvimfiles_old / ".vsnip", silent=silent
    )
    linkf(
        d.s.neovim_old / "init.lua",
        d.t.nvimfiles_old / "init.lua",
        silent=silent,
    )

    linkd(
        d.s.neovim / "ultisnips", d.t.nvimfiles / "ultisnips", silent=silent
    )
    linkf(
        d.s.neovim / "coc-settings.json",
        d.t.nvimfiles / "coc-settings.json",
        silent=silent,
    )
    linkd(d.s.neovim / "lua", d.t.nvimfiles / "lua", silent=silent)
    linkf(
        d.s.neovim / "init.lua",
        d.t.nvimfiles / "init.lua",
        silent=silent,
    )

    # SKK-JISYO.L for skkeleton or eskk
    echo("Downloading SKK-JISYO.L...", SUBARROW)
    skk_target_path = d.t.nvimdata / "SKK-JISYO.L"
    if force or not skk_target_path.exists():
        save_as(
            ungzip(download("https://skk-dev.github.io/dict/SKK-JISYO.L.gz")),
            skk_target_path,
        )

    echo("Installing packages by package manager...", SUBARROW)
    try:
        subprocess.check_output(
            'nvim --headless +"Lazy! sync" +qa',
            shell=True,
            env={
                "PATH": str(os.getenv("PATH")),
                "NVIM_RC_DISABLE_MSG": "1",
            },
        )
    except subprocess.CalledProcessError:
        echo(
            "Error: Installing Neovim plugins failed; please try later",
            SUBARROW,
        )

    echo("Installing LSP additionals...", SUBARROW)
    try:
        subprocess.check_output(
            "nvim --headless"
            + " -c \"lua require'rc.lib.lsp_additionals'.setup()\"",
            shell=True,
            env={
                "PATH": str(os.getenv("PATH")),
                # "NVIM_RC_DISABLE_MSG": "1",
            },
        )
    except subprocess.CalledProcessError:
        echo(
            "Error: Installing LSP extensions failed; please try later",
            SUBARROW,
        )


def setup_emacs(d, *, silent):
    emacsd = d.t.home / ".emacs.d"
    os.makedirs(emacsd, exist_ok=True)
    linkf(d.s.base / "init.el", emacsd / "init.el", silent=silent)


def setup_powershell(d, *, silent):
    # PowerShell はプロファイルが OneDrive に置かれてしまい、symlink が壊れて
    # しまうので、symlink ではなく $profile を編集して再読み込みすることで対応
    # する
    profile_name = "Microsoft.Powershell_profile.ps1"
    for path in d.t.pwshprofiles:
        os.makedirs(path, exist_ok=True)
        with open(path / profile_name, "wt") as f:
            real_profile_path = d.s.base / "WindowsPowerShell" / profile_name
            print(f'$profile = "{real_profile_path}"', file=f)
            print(". $profile", file=f)


def setup_alacritty(d, *, silent):
    alacritty = d.t.config / "alacritty"
    os.makedirs(alacritty, exist_ok=True)
    linkf(
        d.s.base / "alacritty.yml", alacritty / "alacritty.yml", silent=silent
    )


def setup_kitty(d, *, silent):
    linkd(d.s.base / "kitty", d.t.config / "kitty", silent=silent)


def setup_zsh(d, *, silent):
    linkd(d.s.base / "zsh", d.t.home / ".zsh", silent=silent)
    linkf(d.s.base / "zshrc", d.t.home / ".zshrc", silent=silent)
    linkf(d.s.base / "zsh_aliases", d.t.home / ".zsh_aliases", silent=silent)
    linkf(d.s.base / "envvars", d.t.home / ".envvars", silent=silent)


def setup_linuxgui(d, *, silent):
    # tmux
    echo("Linking tmux configuration...", SUBARROW)
    linkf(d.s.base / "tmux.conf", d.t.home / ".tmux.conf", silent=silent)

    # Xorg
    echo("Linking X Server configurations...", SUBARROW)
    linkf(d.s.base / "Xresources", d.t.home / ".Xresources", silent=silent)
    linkf(d.s.base / "xbindkeysrc", d.t.home / ".xbindkeysrc", silent=silent)
    linkd(d.s.base / "xbindkeys", d.t.home / ".xbindkeys", silent=silent)

    # dunst
    echo("Linking dunst configuration...", SUBARROW)
    os.makedirs(d.t.config / "dunst", exist_ok=True)
    linkf(
        d.s.base / "dunstrc", d.t.config / "dunst" / "dunstrc", silent=silent
    )

    # StaloneTray
    echo("Linking StaloneTray configuration...", SUBARROW)
    linkf(
        d.s.base / "stalonetrayrc", d.t.home / ".stalonetrayrc", silent=silent
    )

    # Picom
    echo("Linking Picom configuration...", SUBARROW)
    linkf(d.s.base / "picom.conf", d.t.home / ".picom.conf", silent=silent)

    # XMonad
    echo("Linking XMonad configuration...", SUBARROW)
    linkd(d.s.base / "xmonad", d.t.home / ".xmonad", silent=silent)

    # Sway
    echo("Linking Sway configuration...", SUBARROW)
    linkd(d.s.base / "sway", d.t.config / "sway", silent=silent)


def setup_scripts(d, *, silent):
    os.makedirs(d.t.bin, exist_ok=True)

    echo("Linking dockerman.py to ~/bin/dockerman", SUBARROW)
    if ENV == Platform.WINDOWS:
        with open(d.t.bin / "dockerman.bat", "w") as f:
            f.write(f"@python {d.s.base / 'dockerman.py'} %*")
    else:
        linkf(d.s.base / "dockerman.py", d.t.bin / "dockerman", silent=silent)

    echo("Linking bin/clipboard_client.py to ~/bin/ccli", SUBARROW)
    if ENV == Platform.WINDOWS:
        with open(d.t.bin / "ccli.bat", "w") as f:
            f.write(f"@python {d.s.base / 'bin' / 'clipboard_client.py'} %*")
    else:
        linkf(
            d.s.base / "bin" / "clipboard_client.py",
            d.t.bin / "ccli",
            silent=silent,
        )


def main(*, force, silent):
    dirs = Directories()

    echo("Configuring Git...", ARROW)
    setup_git(dirs, silent=silent)

    echo("Installing Neovim...", ARROW)
    setup_neovim_appimage(dirs)

    echo("Installing NodeJS...", ARROW)
    install_node(dirs, force=force)

    echo("Installing Deno...", ARROW)
    install_deno(dirs, force=force)

    echo("Configuring Neovim...", ARROW)
    setup_neovim(dirs, force=force, silent=silent)

    echo("Configuring Emacs...", ARROW)
    setup_emacs(dirs, silent=silent)

    if ENV == Platform.WINDOWS:
        echo("Configuring PowerShell...", ARROW)
        setup_powershell(dirs, silent=silent)

    if ENV == Platform.WINDOWS:
        echo("Configuring NYAGOS...", ARROW)
        linkf(dirs.s.base / "nyagos", dirs.t.home / ".nyagos", silent=silent)

    echo("Configuring WezTerm...", ARROW)
    linkf(
        dirs.s.base / "wezterm.lua",
        dirs.t.home / ".wezterm.lua",
        silent=silent,
    )

    if ENV != Platform.WINDOWS:
        echo("Configuring Alacritty...", ARROW)
        setup_alacritty(dirs, silent=silent)

    if ENV != Platform.WINDOWS:
        echo("Configuring kitty...", ARROW)
        setup_kitty(dirs, silent=silent)

    if ENV != Platform.WINDOWS:
        echo("Configuring Zsh...", ARROW)
        setup_zsh(dirs, silent=silent)

    # Standalone Window Managers
    if ENV != Platform.WINDOWS:
        echo("Configuring Linux GUI...", ARROW)
        setup_linuxgui(dirs, silent=silent)

    echo("Configuring scripts...", ARROW)
    setup_scripts(dirs, silent=silent)

    echo("Everything done.", ARROW)


if __name__ == "__main__":
    main(force="--force" in argv, silent="--silent" in argv)
