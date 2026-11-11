{
  python3,
  writeShellScriptBin,
}:
writeShellScriptBin "hollow-nv-colorscript" ''
  exec ${python3}/bin/python3 - "$@" <<'PY'
  import colorsys
  import os
  import re
  import sys
  import time

  art = [
      "  ▄▄▄  ▄▄▄       ▄▄ ▄▄                      ▄▄     ▄▄▄ ▄▄▄",
      "  █▀██  ██         ██ ██                     ██▄   ██▀ █▀██  ██▀▀",
      "    ██  ██         ██ ██                     ███▄  ██    ██  ██",
      "    ██████   ▄███▄ ██ ██ ▄███▄▀█▄ █▄ ██▀     ██ ▀█▄██    ██  ██",
      "    ██  ██   ██ ██ ██ ██ ██ ██ ██▄██▄██      ██   ▀██    ██▄ ██",
      "  ▀██▀  ▀██▄▄▀███▀▄██▄██▄▀███▀  ▀██▀██▀    ▀██▀    ██     ▀███▀",
  ]

  defaults = [
      "#000000", "#e06c75", "#85b452", "#e5c07b",
      "#6ca0dc", "#b388ff", "#66c2cd", "#e0e0e0",
      "#2e2e2e", "#ee5c95", "#914760", "#9e2b4b",
      "#5e81ac", "#8f88ac", "#b48ead", "#ffffff",
  ]
  palette = list(defaults)

  seq = os.path.join(
      os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
      "wallust/sequences",
  )
  if os.path.exists(seq):
      data = open(seq, "rb").read().decode("utf-8", "ignore")
      for entry in data.split("\x07"):
          match = re.search(r"\]4;(\d+);#([0-9a-fA-F]{6})", entry)
          if match:
              palette[int(match.group(1))] = "#" + match.group(2)

  def rgb(value):
      value = value.lstrip("#")
      return tuple(int(value[index:index + 2], 16) / 255 for index in (0, 2, 4))

  def hsv(value):
      return colorsys.rgb_to_hsv(*rgb(value))

  colors = list(palette)
  colors.sort(key=lambda value: hsv(value)[0])

  segments = 6
  gradient = []
  for index, color in enumerate(colors):
      next_color = colors[(index + 1) % len(colors)]
      h0, s0, v0 = hsv(color)
      h1, s1, v1 = hsv(next_color)
      if h1 < h0:
          h1 += 1.0
      for step in range(segments):
          amount = step / segments
          hue = h0 + (h1 - h0) * amount
          sat = s0 + (s1 - s0) * amount
          val = v0 + (v1 - v0) * amount
          gradient.append(tuple(round(channel * 255) for channel in colorsys.hsv_to_rgb(hue % 1.0, sat, val)))

  def frame(phase):
      output = []
      for row, line in enumerate(art):
          current = []
          for col, char in enumerate(line):
              if char == " ":
                  current.append(" ")
                  continue
              red, green, blue = gradient[(row + col + phase) % len(gradient)]
              current.append(f"\x1b[38;2;{red};{green};{blue}m{char}")
          output.append("".join(current) + "\x1b[0m")
      return "\n".join(output) + "\n"

  if "--animate" not in sys.argv[1:]:
      sys.stdout.write(frame(0))
      sys.exit(0)

  sys.stdout.write("\x1b[?25l")
  phase = 0
  try:
      while True:
          sys.stdout.write(frame(phase))
          sys.stdout.write("\x1b[6A")
          sys.stdout.flush()
          phase = (phase + 1) % steps
          time.sleep(0.15)
  except KeyboardInterrupt:
      pass
  finally:
      sys.stdout.write("\x1b[?25h")
      sys.stdout.flush()
  PY
''
