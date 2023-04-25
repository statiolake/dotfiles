#!/usr/bin/env python

import os
import sys
from urllib.error import URLError
from urllib.request import Request, urlopen

# dockerman からの接続のときはそれを使う
ADDR = os.environ.get("DOCKERMAN_NATIVE_IP", default="localhost")
PORT = 55232
URL = f"http://{ADDR}:{PORT}"


def check(silent: bool = False):
    try:
        urlopen(Request(URL))
        return True
    except (ConnectionRefusedError, URLError):
        if not silent:
            print(
                f"failed to communicate with server at {URL}",
                file=sys.stderr,
            )
        return False


def copy():
    if not check():
        return
    data = sys.stdin.read()
    req = Request(URL, data=data.encode("utf-8"), method="POST")
    with urlopen(req):
        pass


def paste():
    if not check():
        return
    req = Request(URL)
    with urlopen(req) as res:
        print(res.read().decode("utf-8"), end="")


def main():
    if len(sys.argv) >= 2:
        command = sys.argv[1]
    elif sys.stdin.isatty():
        command = "paste"
    else:
        command = "copy"

    if command == "copy":
        copy()
    elif command == "paste":
        paste()
    elif command == "check":
        sys.exit(0 if check(silent=True) else 1)
    else:
        raise RuntimeError(f"unknown command: {command}")


if __name__ == "__main__":
    main()
