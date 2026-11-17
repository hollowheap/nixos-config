#!/usr/bin/env python3
"""Bin wallust salient colors into semantic ANSI slots in OKLCH."""

import argparse
import json
import math
import os
import re
import subprocess
import sys
import tomllib

ANSI_TARGETS = {
    1: 29.2,   # red
    2: 142.5,  # green
    3: 109.8,  # yellow
    4: 264.1,  # blue
    5: 328.4,  # magenta
    6: 194.8,  # cyan
}
CANDIDATE_SLOTS = (*range(1, 7), *range(9, 15))
MIN_CHROMA = 0.04
MIN_GAP = 0.04
# OKLab L at 0.58 keeps red, blue, and magenta above 4.5:1 contrast against the #000000 background.
LIGHT_HI = 0.72
LIGHT_LO = 0.58
FALLBACK = {"hi": (LIGHT_HI, 0.09), "lo": (LIGHT_LO, 0.09)}
IDW_POWER = 1


def wallust_bin():
    return os.environ.get("WALLUST_BIN", "wallust")


def angular_distance(a, b):
    value = abs(a - b) % 360.0
    return min(value, 360.0 - value)


def signed_offset(hue, target):
    return (hue - target + 180.0) % 360.0 - 180.0


def encode(channel):
    channel = max(0.0, min(1.0, channel))
    return 12.92 * channel if channel <= 0.0031308 else 1.055 * channel ** (1 / 2.4) - 0.055


def decode(channel):
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def hex_to_oklch(color):
    r, g, b = (decode(int(color[i:i + 2], 16) / 255.0) for i in (1, 3, 5))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    lightness = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return lightness, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360.0


def oklab_to_linear(lightness, chroma, hue):
    a = chroma * math.cos(math.radians(hue))
    b = chroma * math.sin(math.radians(hue))
    l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (lightness - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


def in_gamut(rgb):
    return all(-1e-4 <= channel <= 1.0001 for channel in rgb)


def oklch_to_hex(lightness, chroma, hue):
    lightness = max(0.0, min(1.0, lightness))
    rgb = oklab_to_linear(lightness, chroma, hue)
    if not in_gamut(rgb):
        low, high = 0.0, chroma
        for _ in range(24):
            mid = (low + high) / 2.0
            if in_gamut(oklab_to_linear(lightness, mid, hue)):
                low = mid
            else:
                high = mid
        rgb = oklab_to_linear(lightness, low, hue)
    return "#" + "".join(f"{round(encode(channel) * 255):02x}" for channel in rgb)


def salience_palette(image, backend):
    command = [
        wallust_bin(),
        "run",
        "-n",
        "-T",
        "-s",
        "--no-hooks",
        "--print-scheme",
        "-b",
        backend,
        "-c",
        "salience",
        "-p",
        "saliencedarkbalanced16",
        image,
    ]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "wallust failed")
    colors = []
    for line in completed.stdout.splitlines():
        match = re.fullmatch(r"#([0-9a-fA-F]{6})", line.strip())
        if match:
            colors.append("#" + match.group(1))
    if len(colors) < 16:
        raise RuntimeError(f"expected 16 colors, got {len(colors)}")
    return colors[:16]


def neutral(color):
    return oklch_to_hex(hex_to_oklch(color)[0], 0.0, 0.0)


def nearest_slot(hue):
    return min(ANSI_TARGETS, key=lambda slot: angular_distance(hue, ANSI_TARGETS[slot]))


def candidates(colors):
    found = []
    for index in CANDIDATE_SLOTS:
        lightness, chroma, hue = hex_to_oklch(colors[index])
        if chroma >= MIN_CHROMA:
            found.append({"L": lightness, "C": chroma, "h": hue})
    return found


def tier(color, light, slot, drift, source):
    offset = signed_offset(color["h"], ANSI_TARGETS[slot])
    return {
        "L": light,
        "C": color["C"],
        "off": max(-drift, min(drift, offset)),
        "src": source,
    }


def proximity(slot, other):
    return 1.0 / angular_distance(ANSI_TARGETS[slot], ANSI_TARGETS[other]) ** IDW_POWER


def tier_ratio(slot, ratios):
    if not ratios:
        return 1.0
    weights = {other: proximity(slot, other) for other in ratios}
    return sum(weights[other] * ratios[other] for other in ratios) / sum(weights.values())


def bin_tiers(found, drift):
    bins = {slot: [] for slot in ANSI_TARGETS}
    for color in found:
        bins[nearest_slot(color["h"])].append(color)

    anchors, darkest = {}, {}
    for slot, members in bins.items():
        if not members:
            continue
        anchor = max(members, key=lambda color: color["C"])
        darker = [color for color in members if color["L"] <= anchor["L"] - MIN_GAP]
        anchors[slot] = anchor
        if darker:
            darkest[slot] = min(darker, key=lambda color: color["L"])

    ratios = {slot: darkest[slot]["C"] / anchors[slot]["C"] for slot in darkest}
    tiers = {}
    for slot, anchor in anchors.items():
        if slot in darkest:
            lo = tier(darkest[slot], LIGHT_LO, slot, drift, "extracted")
        else:
            scaled = {**anchor, "C": anchor["C"] * tier_ratio(slot, ratios)}
            lo = tier(scaled, LIGHT_LO, slot, drift, "mirrored")
        tiers[slot] = {"hi": tier(anchor, LIGHT_HI, slot, drift, "extracted"), "lo": lo}
    return tiers


def fill_tiers(tiers):
    if not tiers:
        return {
            slot: {
                name: {"L": light, "C": chroma, "off": 0.0, "src": "fallback"}
                for name, (light, chroma) in FALLBACK.items()
            }
            for slot in ANSI_TARGETS
        }
    for slot in ANSI_TARGETS:
        if slot in tiers:
            continue
        weights = {other: proximity(slot, other) for other in tiers}
        total = sum(weights.values())
        tiers[slot] = {
            name: {
                **{
                    key: sum(weights[other] * tiers[other][name][key] for other in tiers) / total
                    for key in ("L", "C", "off")
                },
                "src": "interpolated",
            }
            for name in ("hi", "lo")
        }
    return tiers


def accent_palette(colors, drift):
    found = candidates(colors)
    tiers = fill_tiers(bin_tiers(found, drift) if found else {})
    accents = {}
    for slot, names in tiers.items():
        for name, offset in (("lo", 0), ("hi", 8)):
            value = names[name]
            hue = ANSI_TARGETS[slot] + value["off"]
            accents[slot + offset] = {**value, "h": hue % 360.0, "hex": oklch_to_hex(value["L"], value["C"], hue)}
    return accents


def run_hooks(config_dir):
    try:
        with open(os.path.join(config_dir, "wallust.toml"), "rb") as handle:
            hooks = tomllib.load(handle).get("hooks", {})
    except FileNotFoundError:
        return
    for name, command in hooks.items():
        completed = subprocess.run(["sh", "-c", command], capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            print(f"hook {name} failed: {completed.stderr.strip()}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--no-hooks", action="store_true")
    parser.add_argument("--drift", type=float, default=15.0)
    parser.add_argument("--backend", default="full")
    parser.add_argument("--name", default="extracted")
    parser.add_argument("--templates-dir")
    parser.add_argument(
        "--config-dir",
        default=os.path.join(
            os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
            "wallust",
        ),
    )
    args = parser.parse_args()

    target = salience_palette(args.image, args.backend)
    accents = accent_palette(target, args.drift)

    grays = {slot: neutral(target[slot]) for slot in (7, 8, 15)}
    scheme = {
        "cursor": grays[15],
        "background": "#000000",
        "foreground": grays[15],
        "color0": "#000000",
        "color7": grays[7],
        "color8": grays[8],
        "color15": grays[15],
    }
    for slot in sorted(accents):
        scheme[f"color{slot}"] = accents[slot]["hex"]

    scheme_dir = os.path.join(args.config_dir, "colorschemes")
    os.makedirs(scheme_dir, exist_ok=True)
    scheme_path = os.path.join(scheme_dir, f"{args.name}.json")
    with open(scheme_path, "w", encoding="utf-8") as handle:
        json.dump(scheme, handle, indent=2)
        handle.write("\n")

    if not args.apply:
        return

    command = [wallust_bin(), "cs", "-f", "wallust", "-s"]
    if args.templates_dir:
        command += ["--templates-dir", args.templates_dir]
    command.append(args.name)
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        print(completed.stderr.strip(), file=sys.stderr)
        raise SystemExit(completed.returncode)
    if not args.no_hooks:
        run_hooks(args.config_dir)


if __name__ == "__main__":
    main()
