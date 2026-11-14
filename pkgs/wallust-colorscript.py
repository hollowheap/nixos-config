import argparse
import colorsys
import os
import re
import sys
import time

ART = {
    "hollowheap": [
        "   ▄▄▄  ▄▄▄       ▄▄ ▄▄                    ▄▄▄  ▄▄▄                   ",
        "  █▀██  ██         ██ ██                  █▀██  ██                    ",
        "    ██  ██         ██ ██                    ██  ██                    ",
        "    ██████   ▄███▄ ██ ██ ▄███▄▀█▄ █▄ ██▀    ██████   ▄█▀█▄ ▄▀▀█▄ ████▄",
        "    ██  ██   ██ ██ ██ ██ ██ ██ ██▄██▄██     ██  ██   ██▄█▀ ▄█▀██ ██ ██",
        "  ▀██▀  ▀██▄▄▀███▀▄██▄██▄▀███▀  ▀██▀██▀   ▀██▀  ▀██▄▄▀█▄▄▄▄▀█▄██▄████▀",
        "                                                                 ██   ",
        "                                                                 ▀    ",
    ],
    "nv": [
        "   ▄▄▄  ▄▄▄       ▄▄ ▄▄                      ▄▄     ▄▄▄ ▄▄▄      ",
        "  █▀██  ██         ██ ██                     ██▄   ██▀ █▀██  ██▀▀",
        "    ██  ██         ██ ██                     ███▄  ██    ██  ██  ",
        "    ██████   ▄███▄ ██ ██ ▄███▄▀█▄ █▄ ██▀     ██ ▀█▄██    ██  ██  ",
        "    ██  ██   ██ ██ ██ ██ ██ ██ ██▄██▄██      ██   ▀██    ██▄ ██  ",
        "  ▀██▀  ▀██▄▄▀███▀▄██▄██▄▀███▀  ▀██▀██▀    ▀██▀    ██     ▀███▀  ",
    ],
    "pi": [
        "   ▄▄▄  ▄▄▄       ▄▄ ▄▄                     ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄",
        "  █▀██  ██         ██ ██                   █▀▀███▀▀▀▀███▀  ",
        "    ██  ██         ██ ██                      ███    ███   ",
        "    ██████   ▄███▄ ██ ██ ▄███▄▀█▄ █▄ ██▀      ███    ███   ",
        "    ██  ██   ██ ██ ██ ██ ██ ██ ██▄██▄██       ███    ███   ",
        "  ▀██▀  ▀██▄▄▀███▀▄██▄██▄▀███▀  ▀██▀██▀       ▀███▄  ▀███▄ ",
    ],
}

# Only chromatic ANSI/base16 sequence slots (1..6 and 9..14); exclude
# neutral slots 0 (black), 7 (light gray), 8 (dark gray), and 15 (white).
ACCENT_SLOTS = (1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14)
SEGMENTS = 6


def sequences_path():
    return os.path.join(
        os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
        "wallust/sequences",
    )


def read_palette():
    seq = sequences_path()
    palette = {}
    if os.path.exists(seq):
        data = open(seq, "rb").read().decode("utf-8", "ignore")
        for entry in data.split("\x07"):
            match = re.search(r"\]4;(\d+);#([0-9a-fA-F]{6})", entry)
            if match:
                slot = int(match.group(1))
                if slot in ACCENT_SLOTS:
                    palette[slot] = "#" + match.group(2)
    return [palette[slot] for slot in ACCENT_SLOTS if slot in palette]


def rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) / 255 for index in (0, 2, 4))


def hsv(value):
    return colorsys.rgb_to_hsv(*rgb(value))


def build_gradient(palette):
    colors = [
        color
        for color in palette
        if hsv(color)[1] > 0.05 and 0.15 < hsv(color)[2] < 0.98
    ] or list(palette)
    if not colors:
        return []
    colors.sort(key=lambda value: hsv(value)[0])
    gradient = []
    for index, color in enumerate(colors):
        next_color = colors[(index + 1) % len(colors)]
        r0, g0, b0 = rgb(color)
        r1, g1, b1 = rgb(next_color)
        for step in range(SEGMENTS):
            amount = step / SEGMENTS
            gradient.append(
                (
                    round((r0 + (r1 - r0) * amount) * 255),
                    round((g0 + (g1 - g0) * amount) * 255),
                    round((b0 + (b1 - b0) * amount) * 255),
                )
            )
    return gradient


def frame(lines, gradient, phase):
    output = []
    for row, line in enumerate(lines):
        current = []
        for col, char in enumerate(line):
            if char == " ":
                current.append(" ")
                continue
            if gradient:
                red, green, blue = gradient[(row + col + phase) % len(gradient)]
                current.append(f"\x1b[38;2;{red};{green};{blue}m{char}")
            else:
                slot = ACCENT_SLOTS[(row + col + phase) % len(ACCENT_SLOTS)]
                current.append(f"\x1b[38;5;{slot}m{char}")
        output.append("".join(current) + "\x1b[0m")
    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--art", choices=sorted(ART), default="nv")
    parser.add_argument("--animate", action="store_true")
    args = parser.parse_args()

    lines = ART[args.art]
    seq = sequences_path()
    last_mtime = os.path.getmtime(seq) if os.path.exists(seq) else None
    gradient = build_gradient(read_palette())
    span = len(gradient) or len(ACCENT_SLOTS)

    if not args.animate:
        phase = int(time.time() / 0.15) % span if args.art == "pi" else 0
        sys.stdout.write(frame(lines, gradient, phase) + "\n")
        return

    up = len(lines) - 1
    sys.stdout.write("\x1b[?25l")
    phase = 0
    try:
        while True:
            mtime = os.path.getmtime(seq) if os.path.exists(seq) else None
            if mtime != last_mtime:
                last_mtime = mtime
                gradient = build_gradient(read_palette())
                span = len(gradient) or len(ACCENT_SLOTS)
            sys.stdout.write(frame(lines, gradient, phase))
            sys.stdout.write(f"\x1b[{up}A\r")
            sys.stdout.flush()
            phase = (phase + 1) % span
            time.sleep(0.15)
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write("\x1b[?25h")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
