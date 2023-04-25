#!/usr/bin/env python

# 前提
#   - カレントディレクトリに Dockerfile がある。
#   - Dockerfile は Debian ベースである。(apt を使うので)
# 使い方
#   - 使いたいディレクトリで python run.py する。

import enum
import json
import os
import re
import socket
import subprocess as sp
import sys
from argparse import ArgumentParser, Namespace
from datetime import datetime
from os import PathLike, getcwd
from os.path import basename, dirname, realpath
from pathlib import Path
from subprocess import CalledProcessError
from threading import Event, Thread
from typing import Any, Optional, TypeAlias, Union, cast

AsPath: TypeAlias = Union[bytes, str, PathLike[Any]]


# 表示ヘルパー {{{
def echo(message: str):
    "色付きでメッセージを出力する"
    print("\033[1;33m" + message + "\033[m", file=sys.stderr)


def echo_command(kind: str, cmd: tuple[str, ...]):
    print(f"\033[31m{kind} " + str(cmd) + "\033[m", file=sys.stderr)


# }}}

# 外部コマンド実行ヘルパー {{{
def native_output_of(*cmd: str):
    echo_command("Fetching", cmd)
    return sp.check_output(cmd).decode("utf-8").strip()


def wsl_output_of(*cmd: str):
    if not IS_WINDOWS or not USE_WSL_DOCKER:
        raise RuntimeError("WSL is not allowed in this script.")
    return native_output_of("wsl", "-d", WSL_DISTRO, "-e", *cmd)


def docker_host_output_of(*cmd: str):
    if IS_WINDOWS and USE_WSL_DOCKER:
        return wsl_output_of(*cmd)
    else:
        return native_output_of(*cmd)


def native_spawn(*cmd: str, redir_null: bool):
    echo_command("Spawning", cmd)
    extra_kwargs = {}
    if redir_null:
        extra_kwargs = {
            "stdin": sp.DEVNULL,
            "stdout": sp.DEVNULL,
            "stderr": sp.DEVNULL,
        }
    return sp.Popen(cmd, **extra_kwargs)


def wsl_spawn(*cmd: str, redir_null: bool):
    return native_spawn(
        "wsl", "-d", WSL_DISTRO, "-e", *cmd, redir_null=redir_null
    )


def docker_host_spawn(*cmd: str, redir_null: bool):
    if IS_WINDOWS and USE_WSL_DOCKER:
        return wsl_spawn(*cmd, redir_null=redir_null)
    else:
        return native_spawn(*cmd, redir_null=redir_null)


def native_run(*cmd: str):
    echo_command("Running", cmd)
    return sp.run(cmd, check=True)


def wsl_run(*cmd: str):
    return native_run("wsl", "-d", WSL_DISTRO, "-e", *cmd)


def docker_host_run(*cmd: str):
    if IS_WINDOWS and USE_WSL_DOCKER:
        return wsl_run(*cmd)
    else:
        return native_run(*cmd)


def native_run_tee(*cmd: str):
    def gen():
        echo_command("Teeing", cmd)
        with sp.Popen(cmd, stdout=sp.PIPE, stderr=sp.STDOUT) as proc:
            while True:
                assert proc.stdout is not None
                line = proc.stdout.readline()
                if line:
                    yield line.strip().decode("utf-8")

                if not line and (ret := proc.poll()) is not None:
                    if ret == 0:
                        break
                    raise CalledProcessError(ret, cmd)

    res: list[str] = []
    for line in gen():
        print(line)
        res.append(line)

    return "\n".join(res)


def wsl_run_tee(*cmd: str):
    return native_run_tee("wsl", "-d", WSL_DISTRO, "-e", *cmd)


def docker_host_run_tee(*cmd: str):
    if IS_WINDOWS and USE_WSL_DOCKER:
        return wsl_run_tee(*cmd)
    else:
        return native_run_tee(*cmd)


def native_run_silent(*cmd: str):
    echo_command("Silently running", cmd)
    return sp.run(cmd, stdout=sp.DEVNULL, stderr=sp.DEVNULL, check=True)


def wsl_run_silent(*cmd: str):
    return native_run_silent("wsl", "-d", WSL_DISTRO, "-e", *cmd)


def docker_host_run_silent(*cmd: str):
    if IS_WINDOWS and USE_WSL_DOCKER:
        return wsl_run_silent(*cmd)
    else:
        return native_run_silent(*cmd)


def check_wait(proc: sp.Popen[bytes]):
    proc.wait()
    if proc.returncode != 0:
        raise CalledProcessError(proc.returncode, proc.args)


def docker_host_python():
    if IS_WINDOWS and USE_WSL_DOCKER:
        return "/usr/bin/python3"
    else:
        return sys.executable


def to_docker_host_path(path: AsPath):
    if str(path) == ".":
        return "."
    if IS_WINDOWS and USE_WSL_DOCKER:
        return wsl_output_of("wslpath", "-u", str(path))
    else:
        return str(path)


# }}}

# 環境 {{{
def find_native_ip():
    if IS_WINDOWS and USE_WSL_DOCKER:
        ip_route = wsl_output_of("ip", "route")
        ip_route = [
            line for line in ip_route.splitlines() if "default via" in line
        ]
        if len(ip_route) == 0:
            return None
        ip_route = ip_route[0]
        ip = re.findall(
            r"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}", ip_route
        )
        if len(ip) == 0:
            return None
        return str(ip[0])
    else:
        # FIXME: IP じゃないね
        return "host.docker.internal"


def find_unused_port():
    sock = socket.socket()
    sock.bind(("", 0))
    port = sock.getsockname()[1]
    sock.close()
    return port


def expose_container_port(container_name: str, container_port: int):
    # socat で適当なポートを開ける
    container_ip = docker_container_find_ip(container_name)
    host_port = find_unused_port()
    echo(f"Opening port {host_port}")
    socat_container = docker_run(
        "alpine/socat",
        [
            f"TCP4-LISTEN:{container_port},fork",
            f"TCP4:{container_ip}:{container_port}",
        ],
        interactive=False,
        detach=True,
        ports=[(host_port, container_port)],
        # net="host",
    )
    return host_port, socat_container


# }}}

# 定数 {{{
# 環境
HOME_DIR = Path(os.path.expanduser("~"))
DOTFILES_DIR = Path(dirname(realpath(__file__)))
IS_WINDOWS = os.name == "nt"
IS_LINUX = os.name == "posix"
IS_WSL2: bool = IS_LINUX and ("WSL2" in native_output_of("uname", "-a"))

USE_WSL_DOCKER = True
WSL_DISTRO_ROOTFS_URL = "https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz"
WSL_DISTRO = "custom-docker-host"
RUN_NEOVIM = False  # IS_WINDOWS
RUN_NEOVIM_GUI = False  # IS_WINDOWS
NVIM_PORT = 5432
# }}}

# 型 {{{
class Mode(enum.Enum):
    ATTACH = enum.auto()
    BUILD = enum.auto()
    DOCKER = enum.auto()
    WSL = enum.auto()
    PATH = enum.auto()


class ContainerOptions:
    dockerfile: Path
    image_name: str
    cached_image_name: Optional[str]
    container_name: str
    container_working_directory: str

    def __init__(
        self,
        dockerfile: Path,
        image_name: str,
        cached_image_name: Optional[str],
        container_name: str,
        container_working_directory: str,
    ):
        if not dockerfile.exists():
            raise RuntimeError(f"{dockerfile} does not exist")

        self.dockerfile = dockerfile
        self.image_name = image_name
        self.cached_image_name = cached_image_name
        self.container_name = container_name
        self.container_working_directory = container_working_directory


# }}}

# 引数処理 {{{
def _options_generate_image_name(dockerfile: Path):
    name = dockerfile.name
    base = basename(getcwd())
    if name == "Dockerfile":
        # 名前が Dockerfile ならシンプルにプロジェクト名を利用する
        return base

    if name.startswith("Dockerfile."):
        # Dockerfile.tex など suffix がついている場合はプロジェクト名
        # に suffix を追加したものとする
        suffix = name[len("Dockerfile.") :]
        return f"{base}.{suffix}"

    # 名前が Dockerfile ですらないならその名前をまるごと suffix と
    # してプロジェクト名に追加したものとする
    return f"{base}.{name}"


def _options_attach_register_arguments(parser: ArgumentParser):
    parser.add_argument(
        "dockerfile",
        type=str,
        default="Dockerfile",
        nargs="?",
        help="Dockerfile name",
    )

    parser.add_argument(
        "-i",
        "--image-name",
        type=str,
        default=None,
        help="Image name",
    )

    parser.add_argument(
        "-c",
        "--container-name",
        type=str,
        default=None,
        help="Container name",
    )

    parser.add_argument(
        "-r",
        "--rebuild-dotfiles",
        action="store_true",
        help="Rebuild dotfiles to ensure latest dotfiles",
    )

    parser.add_argument(
        "-w",
        "--container-working-directory",
        type=str,
        default="/workspace",
        help="Working directory inside container",
    )

    parser.add_argument(
        "--force-recreate-container",
        "-u",
        action="store_true",
        help="Force recreate container to ensure latest volume mount from dotfiles",
    )


class SubcommandOptions:
    pass


class AttachOptions(SubcommandOptions):
    # コンテナオプション
    container: ContainerOptions

    # dotfiles が変更されていたときに更新するかどうか
    rebuild_dotfiles: bool

    # コンテナ内での作業ディレクトリ
    container_working_directory: str

    # コンテナを強制的に再生成するかどうか
    force_recreate_container: bool

    def __init__(self, args: Namespace):
        dockerfile = Path(args.dockerfile)
        image_name = args.image_name or _options_generate_image_name(
            dockerfile
        )
        container_name = args.container_name or image_name
        container_working_directory = args.container_working_directory

        self.container = ContainerOptions(
            dockerfile,
            image_name,
            None,
            container_name,
            container_working_directory,
        )
        self.rebuild_dotfiles = args.rebuild_dotfiles
        self.force_recreate_container = args.force_recreate_container


def _options_build_register_arguments(parser: ArgumentParser):
    parser.add_argument(
        "dockerfile",
        type=str,
        default="Dockerfile",
        nargs="?",
        help="Dockerfile name",
    )

    parser.add_argument(
        "-i", "--image-name", type=str, default=None, help="Image name"
    )


def _options_path_register_arguments(parser: ArgumentParser):
    parser.add_argument("path", type=str, help="local path to convert from")


class BuildOptions(SubcommandOptions):
    dockerfile: Path
    image_name: str

    def __init__(self, args: Namespace):
        self.dockerfile = Path(args.dockerfile)
        self.image_name = args.image_name or _options_generate_image_name(
            self.dockerfile
        )


class DockerOptions(SubcommandOptions):
    args: list[str]

    def __init__(self, extra: list[str]):
        self.args = extra


class WSLOptions(SubcommandOptions):
    args: list[str]

    def __init__(self, extra: list[str]):
        self.args = extra


class PathOptions(SubcommandOptions):
    path: Path

    def __init__(self, args: Namespace):
        self.path = Path(args.path)


class Options:
    # 処理モード
    mode: Mode
    subcommand_options: SubcommandOptions

    def __init__(self, args: Namespace, extra: list[str]):
        allow_extra = False
        self.mode = args.mode
        if args.mode == Mode.ATTACH:
            self.subcommand_options = AttachOptions(args)
        elif args.mode == Mode.BUILD:
            self.subcommand_options = BuildOptions(args)
        elif args.mode == Mode.DOCKER:
            allow_extra = True
            self.subcommand_options = DockerOptions(extra)
        elif args.mode == Mode.WSL:
            allow_extra = True
            self.subcommand_options = WSLOptions(extra)
        elif args.mode == Mode.PATH:
            self.subcommand_options = PathOptions(args)
        else:
            raise RuntimeError(f"unknown mode: {args.mode}")

        if not allow_extra and not len(extra) == 0:
            raise RuntimeError(f"unrecognized arguments: {extra}")


def options_build_parser():
    parser = ArgumentParser(
        description="Prepare your customized docker environments"
    )

    subparsers = parser.add_subparsers()
    parser_attach = subparsers.add_parser(
        "attach", description="Attach to existing Dockerfile"
    )
    _options_attach_register_arguments(parser_attach)
    parser_attach.set_defaults(mode=Mode.ATTACH)

    parser_build = subparsers.add_parser(
        "build", description="Build an image using specified Dockerfile"
    )
    _options_build_register_arguments(parser_build)
    parser_build.set_defaults(mode=Mode.BUILD)

    parser_docker = subparsers.add_parser(
        "docker", description="Execute raw docker command"
    )
    parser_docker.set_defaults(mode=Mode.DOCKER)

    parser_wsl = subparsers.add_parser(
        "wsl", description="Execute raw wsl command"
    )
    parser_wsl.set_defaults(mode=Mode.WSL)

    parser_path = subparsers.add_parser(
        "path", description="Convert local path to docker host's path"
    )
    _options_path_register_arguments(parser_path)
    parser_path.set_defaults(mode=Mode.PATH)

    return parser


def options_parse():
    parser = options_build_parser()
    args, extra = parser.parse_known_args()
    return Options(args, extra)


# }}}

# Docker {{{
def docker_wsl_distro_dir_path(distro_name: str):
    return HOME_DIR / "wsl-distros" / distro_name


def docker_wsl_prepare_distro():
    distro_dir_path = docker_wsl_distro_dir_path(WSL_DISTRO)
    distro_root_path = distro_dir_path / "root"
    download_path = distro_dir_path / "rootfs.tar.gz"
    os.makedirs(distro_root_path, exist_ok=True)
    if not download_path.exists():
        native_run(
            "curl", "-L", WSL_DISTRO_ROOTFS_URL, "-o", str(download_path)
        )
    native_run(
        "wsl",
        "--import",
        WSL_DISTRO,
        str(distro_root_path),
        str(download_path),
    )


def docker_wsl_setup_docker_on_distro():
    wsl_run("sh", "-c", "curl -fsSL https://get.docker.com/ | sh")
    wsl_run(
        "sh",
        "-c",
        """mkdir -p ~/.docker && echo '{"detachKeys":"ctrl-^"}' > ~/.docker/config.json""",
    )
    wsl_run(
        "sh",
        "-c",
        """mkdir -p /etc/docker && echo '{"features":{"buildkit":true}}' > /etc/docker/daemon.json""",
    )

    # 起動時に service docker start
    wsl_run("sh", "-c", """echo '[boot]' > /etc/wsl.conf""")
    wsl_run(
        "sh",
        "-c",
        """echo 'command="service docker start"' >> /etc/wsl.conf""",
    )


def docker_wsl_fix_time():
    utc_now = datetime.utcnow()
    date_formatted = utc_now.isoformat() + "Z"
    wsl_run_silent("date", "--rfc-3339=ns", "--set", date_formatted)


def docker_wsl_prepare():
    if not IS_WINDOWS or not USE_WSL_DOCKER:
        return

    try:
        wsl_run_silent("which", "docker")
    except CalledProcessError:
        echo("Preparing WSL2 distro to host docker, please wait...")
        docker_wsl_prepare_distro()
        docker_wsl_setup_docker_on_distro()
    docker_wsl_fix_time()


def docker_check_buildkit():
    if IS_WINDOWS and not USE_WSL_DOCKER:
        # Windows はデフォルトで buildkit
        return True

    try:
        conf_path = "/etc/docker/daemon.json"
        conf_file = docker_host_output_of("cat", conf_path)
        conf = json.loads(conf_file)
        return bool(conf["features"]["buildkit"])
    except (FileNotFoundError, KeyError):
        return False


def docker_image_exists(name: str):
    return docker_host_output_of("docker", "images", name, "-q") != ""


def docker_image_created_at(name: str):
    assert docker_image_exists(name)
    return _docker_parse_time(
        docker_host_output_of(
            "docker", "images", name, "--format", "{{.CreatedAt}}"
        )
    )


def docker_image_list_containers(image_name: str):
    return [
        container.strip()
        for container in docker_host_output_of(
            "docker",
            "ps",
            "-a",
            *["--filter", f"ancestor={image_name}"],
            "-q",
        ).splitlines()
    ]


def docker_image_build(
    image_name: str, project_dir: AsPath, dockerfile: AsPath
):
    log = docker_host_run_tee(
        "docker",
        "build",
        "--progress=plain",
        *["-t", image_name],
        *["-f", to_docker_host_path(dockerfile)],
        to_docker_host_path(project_dir),
    )

    # FIXME: かなりハックな更新確認
    # ログの中から CACHED と DONE を抜き出す。
    result_pattern = re.compile(r"^#\d* (CACHED|DONE)")
    log = [
        line
        for line in log.splitlines()
        if result_pattern.search(line) is not None
    ]

    # log の最後から一つ前のものが DONE なら更新されているはず...
    if len(log) < 2:
        raise RuntimeError("failed to parse buildkit output")
    return "DONE" in log[-2]


def docker_image_safe_remove(name: str):
    if not docker_image_exists(name):
        return False
    for container in docker_image_list_containers(name):
        echo(f"Removing containers based on image {name}, please wait...")
        docker_container_safe_remove(container)

    docker_host_run("docker", "image", "rm", name)
    return True


def docker_container_exists(name: str, status: Optional[str] = None):
    return (
        docker_host_output_of(
            "docker",
            "ps",
            "-aq",
            *["--filter", f"name={name}"],
            *(["--filter", f"status={status}"] if status is not None else []),
        )
        != ""
    )


def docker_container_created_at(name: str):
    assert docker_container_exists(name)
    return _docker_parse_time(
        docker_host_output_of(
            "docker",
            "ps",
            "-a",
            *["--filter", f"name={name}"],
            *["--format", "{{.CreatedAt}}"],
        )
    )


def docker_container_find_ip(name: str):
    assert docker_container_exists(name)
    return docker_host_output_of(
        "docker",
        "container",
        "inspect",
        name,
        "--format",
        "{{.NetworkSettings.IPAddress}}",
    )


def docker_container_start(name: str):
    docker_host_run("docker", "start", name)


def docker_container_stop(name: str):
    docker_host_run("docker", "stop", name)


def docker_run(
    image_name: str,
    args: list[str],
    *,
    interactive: bool = True,
    detach: bool = False,
    remove: bool = True,
    ports: Optional[list[tuple[int, int]]] = None,
    net: Optional[str] = None,
):
    if not ports:
        ports = []

    return docker_host_output_of(
        "docker",
        "run",
        *(["-it"] if interactive else []),
        *(["--detach"] if detach else []),
        *(["--rm"] if remove else []),
        *(["--net", net] if net else []),
        *sum((["--publish", f"{h}:{c}"] for h, c in ports), []),
        image_name,
        *args,
    )


def docker_container_create(
    image_name: str,
    container_name: str,
    extra_args: Optional[list[str]] = None,
):
    if extra_args is None:
        extra_args = []

    docker_host_run(
        "docker",
        "create",
        "-it",
        *extra_args,
        "--name",
        container_name,
        image_name,
    )


def docker_container_safe_remove(name: str):
    if docker_container_exists(name, status="running"):
        echo("Stopping container before removal, please wait...")
        docker_container_stop(name)

    if docker_container_exists(name):
        docker_host_run("docker", "rm", name)
        return True
    return False


def docker_commit(container_name: str, image_name: str):
    docker_host_run("docker", "commit", container_name, image_name)


def docker_exec(
    container_name: str,
    shellcmd: str,
    *,
    interactive: bool = False,
    envs: Optional[dict[str, str]] = None,
):
    if not envs:
        envs = {}

    return docker_host_run(
        "docker",
        "exec",
        *["-it"] if interactive else [],
        *sum(
            (["--env", f"{key}={value}"] for key, value in envs.items()), []
        ),
        container_name,
        "/bin/sh",
        "-c",
        shellcmd,
    )


def docker_mount_spec(
    source: AsPath, target: AsPath, mount_type: str = "bind"
):
    source = to_docker_host_path(source)
    # target は docker コンテナの中のパスなので変換しない
    return ",".join(
        [
            f"source={source}",
            f"target={target}",
            f"type={mount_type}",
        ]
    )


def _docker_parse_time(raw: str):
    # JST などの文字表記によるタイムゾーンを切り落とす
    # (%Z は UTC, GMT 以外には自分のタイムゾーンしか拾えないらしい)
    raw = " ".join(raw.split()[:3])
    return datetime.strptime(raw, "%Y-%m-%d %H:%M:%S %z")


# }}}

# 作業 {{{
def ensure_dotfiles_image(rebuild_dotfiles: bool):
    if not rebuild_dotfiles and docker_image_exists("dotfiles"):
        # なるべくなら dotfiles も最新のものを使いたいところではあるが、
        # dotfiles のビルドは重いので、--rebuild-dotfiles で明示的にリビルドす
        # るよう指定されておらず、dotfiles のイメージが既に存在する場合は、改
        # めてビルドすることなくそのイメージを使い回す。
        echo("Reusing existing dotfiles, skipping build of dotfiles.")
        return False

    echo("Building dotfiles, please wait...")
    return docker_image_build(
        "dotfiles", DOTFILES_DIR, DOTFILES_DIR / "Dockerfile"
    )


def recreate_dotfiles_container():
    echo("Creating dotfiles container, please wait...")
    docker_container_safe_remove("dotfiles")
    docker_container_create("dotfiles", "dotfiles")


def ensure_dotfiles_container(rebuild_dotfiles: bool):
    # まずは dotfiles のイメージの準備
    updated = ensure_dotfiles_image(rebuild_dotfiles)
    needs_recreate = updated or not docker_container_exists("dotfiles")

    # もし dotfiles が更新されていた場合は改めてコンテナを作成する
    if needs_recreate:
        recreate_dotfiles_container()

    return updated


def ensure_project_image(cont: ContainerOptions):
    echo(f"Building {cont.image_name}, please wait...")
    updated = docker_image_build(cont.image_name, ".", cont.dockerfile)
    if updated and cont.cached_image_name:
        # 古いキャッシュがあれば消しておく
        docker_image_safe_remove(cont.cached_image_name)
    return updated


def find_display():
    if IS_LINUX:
        return os.environ.get("DISPLAY", default=None)

    if IS_WINDOWS and USE_WSL_DOCKER:
        return f"{find_native_ip()}:0.0"


def recreate_project_container(cont: ContainerOptions):
    echo(f"Creating {cont.container_name} container, please wait...")
    docker_container_safe_remove(cont.container_name)

    # いろいろなツールのインストールは重いのでキャッシュがあるならそちらを使う
    is_cached = cont.cached_image_name and docker_image_exists(
        cont.cached_image_name
    )

    workspace_mount_spec = docker_mount_spec(
        getcwd(), cont.container_working_directory
    )

    # skkeleton の辞書ファイルをマウントしたい
    skkeleton_jisyo_mount_args: list[str] = []
    if (HOME_DIR / "Dropbox").exists():
        skkeleton_jisyo = HOME_DIR / "Dropbox" / ".skkeleton"
    else:
        skkeleton_jisyo = HOME_DIR / ".skkeleton"
    skkeleton_jisyo.touch()
    skkeleton_jisyo_mount_args = [
        "--mount",
        docker_mount_spec(
            skkeleton_jisyo,
            "/root/.skkeleton",
        ),
    ]

    # clipboard_client がホスト側の clipboard_server へ接続できるようにホスト
    # へ host.docker.internal でアクセスできるようにする
    # これは Docker Desktop for Windows, Docker Desktop for Mac では最初からそ
    # うらしいけど、Linux や WSL で Docker Desktop を使わないで構成している場
    # 合は入れる
    if IS_WINDOWS and not USE_WSL_DOCKER:
        # Docker for Windows では不要
        host_docker_internal = []
    else:
        host_docker_internal = [
            "--add-host=host.docker.internal:host-gateway"
        ]

    # WSLg を使っているかどうかの判断を /tmp/wslg/PulseServer で確認 (雑...)
    if Path("/mnt/wslg/PulseServer").exists():
        wslg_mount_specs = [
            docker_mount_spec("/tmp/.X11-unix", "/tmp/.X11-unix"),
            docker_mount_spec("/mnt/wslg", "/mnt/wslg"),
        ]
    else:
        wslg_mount_specs = []

    if IS_LINUX and not IS_WSL2:
        # X11 へのアクセスを許可する
        native_run("xhost", "+local:")
        x11_mount_specs = [
            docker_mount_spec("/tmp/.X11-unix", "/tmp/.X11-unix"),
        ]
    else:
        x11_mount_specs = []

    docker_container_create(
        cast(str, cont.cached_image_name) if is_cached else cont.image_name,
        cont.container_name,
        [
            *["--volumes-from", "dotfiles"],
            *["--mount", workspace_mount_spec],
            *skkeleton_jisyo_mount_args,
            *host_docker_internal,
            *sum((["--mount", spec] for spec in wslg_mount_specs), []),
            *sum((["--mount", spec] for spec in x11_mount_specs), []),
        ],
    )


def ensure_project_container(
    cont: ContainerOptions,
    force_recreate: bool,
):
    # もしこのプロジェクトコンテナが dotfiles だったらすでに準備は完了している
    # はず
    if cont.image_name == "dotfiles":
        return False

    # まずはイメージの準備
    updated = ensure_project_image(cont)

    needs_recreate = (
        force_recreate
        or updated
        or not docker_container_exists(cont.container_name)
        or (
            docker_container_created_at("dotfiles")
            > docker_container_created_at(cont.container_name)
        )
    )

    if needs_recreate:
        recreate_project_container(cont)

    return needs_recreate


def ensure_project_container_started(cont: ContainerOptions):
    # バックグラウンドでコンテナを実行する
    if docker_container_exists(cont.container_name, status="running"):
        return
    echo(f"Starting {cont.container_name} container, please wait...")
    docker_container_start(cont.container_name)


def install_required_packages_to_container(cont: ContainerOptions):
    def execute(cmd: str):
        docker_exec(cont.container_name, cmd)

    def debian_installer(packages: list[str]):
        return execute(
            " && ".join(
                [
                    "apt-get update",
                    "apt-get install -y " + " ".join(packages),
                ]
            ),
        )

    debian_packages = [
        "zsh",
        "git",
        "curl",
        "ripgrep",
        "python3",
        "python3-venv",
        "python3-pip",
        "python-is-python3",
        "iputils-ping",
        "net-tools",
    ]

    # TODO: alpine
    installer = debian_installer
    packages = debian_packages

    return installer(packages)


def install_neovim_to_container(cont: ContainerOptions):
    def execute(cmd: str):
        return docker_exec(cont.container_name, cmd)

    url = "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz"
    execute(
        " && ".join(
            [
                "mkdir -p /tmp",
                "cd /tmp",
                f"curl -L {url} -o nvim-linux64.tar.gz",
                "tar xvzf nvim-linux64.tar.gz --strip-components 1 -C /usr/local",
            ]
        ),
    )

    # pynvim も入れておかねば
    try:
        execute("which pip3")
        pip_cmd = "pip3"
    except CalledProcessError:
        pip_cmd = "pip"

    execute(f"{pip_cmd} install pynvim")


def rerun_dotfiles_on_container(cont: ContainerOptions):
    def execute(cmd: str):
        return docker_exec(cont.container_name, cmd)

    # コマンド python3 / python の違いを吸収しておく
    try:
        execute("which python3")
        python_cmd = "python3"
    except CalledProcessError:
        python_cmd = "python"
    execute(f"{python_cmd} /root/dotfiles/install.py")


def cache_project_container(cont: ContainerOptions):
    assert cont.cached_image_name
    docker_commit(cont.container_name, cont.cached_image_name)


def ensure_tools_installed_in_container(cont: ContainerOptions):
    def is_executable(package_name: str):
        try:
            docker_exec(cont.container_name, f"which {package_name}")
            return True
        except CalledProcessError:
            return False

    tools = ["zsh", "curl", "python", "nvim"]
    if not all(is_executable(name) for name in tools):
        install_required_packages_to_container(cont)
        install_neovim_to_container(cont)
        rerun_dotfiles_on_container(cont)

    if cont.cached_image_name is not None:
        echo("caching container...")
        cache_project_container(cont)


def populate_container_envvars():
    envs = {
        # Linux / WSLg
        "DISPLAY": find_display(),
        "WAYLAND_DISPLAY": os.environ.get("WAYLAND_DISPLAY", default=None),
        "XDG_RUNTIME_DIR": os.environ.get("XDG_RUNTIME_DIR", default=None),
        "PULSE_SERVER": os.environ.get("PULSE_SERVER", default=None),
        # GPU
        "NVIDIA_VISIBLE_DEVICES": "all",
        "NVIDIA_DRIVER_CAPABILITIES": "all",
        "DOCKERMAN_ATTACHED": "1",
        "DIRECT_NVIM": "1" if RUN_NEOVIM else "0",
        "DOCKERMAN_NATIVE_IP": find_native_ip(),
    }
    return {key: value for key, value in envs.items() if value}


def run_neovim(cont: ContainerOptions, envs: dict[str, str]):
    neovim_finished = Event()
    neovim_gui_observer = Thread(target=lambda: None)

    socat_container = None
    try:
        if RUN_NEOVIM_GUI:
            # NVIM_PORT につながるポートを開ける
            host_port, socat_container = expose_container_port(
                cont.container_name, NVIM_PORT
            )

            # Neovim-qt を開き監視するスレッドを作る
            #
            # Neovim が終了していないのに GUI がクラッシュしたら繰り返し起動す
            # る
            def keep_running_neovim_gui():
                first = True
                while not neovim_finished.wait(timeout=3):
                    if not first:
                        echo(
                            "GUI finished before Neovim finishes, reconnecting..."
                        )
                    first = False
                    native_run(
                        "nvim-qt",
                        "--server",
                        f"localhost:{host_port}",
                    )

            neovim_gui_observer = Thread(target=keep_running_neovim_gui)

        neovim_gui_observer.start()
        docker_exec(
            cont.container_name,
            f"nvim --listen 0.0.0.0:{NVIM_PORT}"
            + (" --headless" if RUN_NEOVIM_GUI else ""),
            interactive=not RUN_NEOVIM_GUI,
            envs=envs,
        )
    finally:
        neovim_finished.set()
        neovim_gui_observer.join()
        if socat_container:
            docker_container_stop(socat_container)


def launch_wait(cont: ContainerOptions, envs: dict[str, str]):
    # clipboard_server を起動する
    #
    # 本当はプロセスが起動していないときのみとしたかったのだが、Windows でいい
    # 感じにする方法が思いつかなかったので適当に投げることにする
    #
    # ポートは予め指定したものだから複数起動することはできないはず...
    native_spawn(
        sys.executable,
        str(DOTFILES_DIR / "bin" / "clipboard_server.py"),
        redir_null=True,
    )

    if RUN_NEOVIM:
        run_neovim(cont, envs)
    else:
        # zsh を開く
        docker_exec(
            cont.container_name, "/usr/bin/zsh", interactive=True, envs=envs
        )

    # clipboard_server を終了... しない！
    # 複数の docker クライアントで共有してほしいので
    # clipboard_server.kill()


# }}}


def mode_attach(opts: AttachOptions):
    remove_container = False

    try:
        # まずは dotfiles のコンテナを準備
        updated_dotfiles = ensure_dotfiles_container(opts.rebuild_dotfiles)

        # プロジェクトのコンテナも準備
        # dotfiles が更新されていれば強制再生成
        ensure_project_container(
            opts.container, opts.force_recreate_container or updated_dotfiles
        )

        # プロジェクトコンテナを起動
        ensure_project_container_started(opts.container)

        try:
            # コンテナ内に各種ツールがインストールされていることを保証する
            ensure_tools_installed_in_container(opts.container)
        except CalledProcessError:
            # インストールが成功していないはずなので後で削除しておく
            remove_container = True
            raise

        # コンテナを開いて終了されるまで待つ
        launch_wait(opts.container, populate_container_envvars())
    except KeyboardInterrupt:
        pass
    finally:
        if remove_container:
            echo("Removing container, please wait...")
            docker_container_safe_remove(opts.container.container_name)
    return 0


def mode_build(opts: BuildOptions):
    docker_image_build(opts.image_name, ".", opts.dockerfile)


def mode_docker(opts: DockerOptions):
    docker_host_run("docker", *opts.args)


def mode_wsl(opts: WSLOptions):
    docker_host_run(*opts.args)


def mode_path(opts: PathOptions):
    print(to_docker_host_path(opts.path))


def main():
    docker_wsl_prepare()

    if not docker_check_buildkit():
        echo("Buildkit is not enabled.")
        return 1

    opts = options_parse()
    subopts = opts.subcommand_options
    if opts.mode == Mode.ATTACH:
        assert isinstance(subopts, AttachOptions)
        return mode_attach(subopts)
    elif opts.mode == Mode.BUILD:
        assert isinstance(subopts, BuildOptions)
        return mode_build(subopts)
    elif opts.mode == Mode.DOCKER:
        assert isinstance(subopts, DockerOptions)
        return mode_docker(subopts)
    elif opts.mode == Mode.WSL:
        assert isinstance(subopts, WSLOptions)
        return mode_wsl(subopts)
    elif opts.mode == Mode.PATH:
        assert isinstance(subopts, PathOptions)
        return mode_path(subopts)

    return 1


if __name__ == "__main__":
    sys.exit(main())
