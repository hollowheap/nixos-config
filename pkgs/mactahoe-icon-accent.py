#!/usr/bin/env python3
import colorsys
import os
import subprocess
import sys

def get_theme_for_color(hex_c, mode="dark"):
    hex_c = hex_c.lstrip("#")
    if len(hex_c) != 6:
        return f"mactahoe-icon-theme-latest-{mode}"

    try:
        r, g, b = [int(hex_c[i:i+2], 16) / 255.0 for i in (0, 2, 4)]
    except ValueError:
        return f"mactahoe-icon-theme-latest-{mode}"

    h, s, v = colorsys.rgb_to_hsv(r, g, b)

    variants = {
        "blue": (0.59, 1.0, 0.99),
        "green": (0.35, 0.82, 0.85),
        "grey": (0.0, 0.0, 0.41),
        "nord": (0.61, 0.32, 0.52),
        "orange": (0.08, 0.89, 1.0),
        "purple": (0.77, 0.59, 0.86),
        "red": (0.01, 0.83, 1.0),
        "yellow": (0.12, 0.89, 1.0),
    }

    if s < 0.12:
        var = "grey"
    else:
        def score(name, hsv):
            vh, vs, vv = hsv
            dh = min(abs(h - vh), 1.0 - abs(h - vh))
            return dh * 10.0 + abs(s - vs) + abs(v - vv)
        var = min([v for v in variants if v != "grey"], key=lambda x: score(x, variants[x]))

    return f"mactahoe-icon-theme-latest-{var}-{mode}"

def main():
    apply_mode = "--apply" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--apply"]

    cache_dir = os.path.expanduser(os.environ.get("XDG_CACHE_HOME", "~/.cache")) + "/noctalia"
    rendered_file = os.path.join(cache_dir, "dconf-theme.txt")
    cache_file = os.path.join(cache_dir, "dconf-theme.cache")

    hex_c = None
    mode = "dark"

    if args:
        hex_c = args[0]
        if len(args) > 1:
            mode = args[1]
    elif os.path.isfile(rendered_file):
        try:
            with open(rendered_file, "r") as f:
                parts = f.read().strip().split()
                if parts:
                    hex_c = parts[0]
                    if len(parts) > 1:
                        mode = parts[1]
        except Exception:
            pass

    if not hex_c:
        theme = f"mactahoe-icon-theme-latest-{mode}"
        print(theme)
        return

    clean_hex = hex_c.lstrip("#")
    theme = get_theme_for_color(clean_hex, mode)

    if apply_mode:
        os.makedirs(cache_dir, exist_ok=True)
        cached = ""
        if os.path.isfile(cache_file):
            try:
                with open(cache_file, "r") as f:
                    cached = f.read().strip()
            except Exception:
                pass

        current = f"{clean_hex} {mode} {theme}"
        if cached == current:
            return

        try:
            with open(cache_file, "w") as f:
                f.write(current + "\n")
        except Exception:
            pass

        subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/icon-theme", f"'{theme}'"], capture_output=True)
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", theme], capture_output=True)

    print(theme)

if __name__ == "__main__":
    main()
