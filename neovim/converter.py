import sys


def parse_use(lines):
    pass


def extract_uses(lines):
    uses = []
    while len(lines) > 0:
        line = lines.pop(0)
        if line.startswith("use {") or line.startswith("use_as_deps {"):
            use = []
            while len(lines) > 0 and (line := lines.pop(0)) != "}":
                use.append(line)
            uses.append(use)
        elif line.startswith("use '") or line.startswith('use "'):
            use = line[4:]
            uses.append([use])
        elif line.startswith("use_as_deps '") or line.startswith(
            'use_as_deps "'
        ):
            use = line[12:]
            uses.append([use])
        elif line.startswith("use"):
            raise RuntimeError(
                f"line starts with use but unknown kind: {line}"
            )

    return uses


lines = [
    line.rstrip()
    for line in open(sys.argv[1], "r", encoding="utf-8").readlines()
]

for use in extract_uses(lines):
    try:
        print("{\n" + "\n".join(use) + "\n},")
    except:
        print(f"ignored {use[0]} for error", file=sys.stderr)
