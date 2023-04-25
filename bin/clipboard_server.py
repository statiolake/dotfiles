#!/usr/bin/env python

import functools
import os
import subprocess as sp
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

ADDR = "0.0.0.0"
PORT = 55232

# 環境
def detect_env():
    name: str = os.name
    if name == "nt":
        return "windows"
    if name == "posix":
        if "WSL2" in sp.check_output(["uname", "-a"]).decode("utf-8"):
            return "wsl2"
        return "linux"
    return None


# 受け付けてもいいアドレス
def populate_allowed_address():
    allowed: list[str] = []

    # localhost は OK
    allowed += ["localhost", "127.0.0.1"]

    # Docker の諸々を含んでいいことにする
    try:
        output = sp.check_output(["docker", "ps", "-q"], encoding="utf-8")
        containers = [s.strip() for s in (output.splitlines())]
        if len(containers) > 0:
            output = sp.check_output(
                [
                    "docker",
                    "container",
                    "inspect",
                    *containers,
                    "-f",
                    "{{.NetworkSettings.IPAddress}}",
                ],
                encoding="utf-8",
            )
            allowed += [s.strip() for s in output.splitlines()]
    except (FileNotFoundError, sp.CalledProcessError):
        # エラーになるなら特に追加しない
        pass

    # custom-docker-host の WSL からの着信も許す
    try:
        for ip in sp.check_output(
            ["wsl", "-d", "custom-docker-host", "hostname", "-I"],
            encoding="utf-8",
        ).split():
            if ip != "172.17.0.1":
                allowed.append(ip)
    except (FileNotFoundError, sp.CalledProcessError):
        # エラーになるなら特に追加しない
        pass

    # 空のものを除く
    allowed = [s for s in allowed if s != ""]

    return allowed


ENV = detect_env()


def get_clipboard():
    if ENV == "windows":
        return sp.check_output(["win32yank.exe", "-o"])
    if ENV == "wsl2":
        return sp.check_output(["win32yank.exe", "-o", "--lf"])
    if ENV == "linux":
        return sp.check_output(["xsel", "-bo"])
    raise RuntimeError(f"environment {ENV} not supported yet")


def set_clipboard(value: bytes):
    if ENV == "windows":
        return sp.check_output(["win32yank.exe", "-i", "--crlf"], input=value)
    if ENV == "wsl2":
        return sp.check_output(["win32yank.exe", "-i"], input=value)
    if ENV == "linux":
        return sp.check_output(["xsel", "-bi"], input=value)
    raise RuntimeError(f"environment {ENV} not supported yet")


class HTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):  # pylint: disable=invalid-name
        allowed = populate_allowed_address()
        print("allowed:", allowed)
        if self.client_address[0] not in allowed:
            self.send_response(403)
            self.end_headers()
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(get_clipboard())

    def do_POST(self):  # pylint: disable=invalid-name
        allowed = populate_allowed_address()
        print("allowed:", allowed)
        if self.client_address[0] not in allowed:
            self.send_response(403)
            self.end_headers()
            return

        length = int(self.headers["Content-Length"])
        set_clipboard(self.rfile.read(length))
        self.send_response(200)
        self.end_headers()


def main():
    try:
        with HTTPServer((ADDR, PORT), HTTPRequestHandler) as server:
            server.serve_forever()
    except OSError as ex:
        print(ex, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
