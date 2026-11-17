{ lib, ... }:
{
  programs.fastfetch.enable = true;
  programs.fastfetch.settings =
    let
      padRight =
        len: filler: str:
        let
          needed = len - builtins.stringLength str;
        in
        if needed > 0 then str + lib.strings.replicate needed filler else str;
      mkField =
        color: icon: field: type: opts:
        let
          colorCode = toString (color + 90);
          paddedField = padRight 9 " " field;
        in
        {
          key = "│ {#${colorCode}}${icon} ${paddedField}{#keys}│";
          inherit type;
        }
        // opts;
    in
    {
      logo.color = {
        "1" = "94";
        "2" = "96";
        "3" = "94";
        "4" = "96";
        "5" = "94";
        "6" = "96";
      };
      display = {
        color = {
          keys = "96";
          title = "1;96";
        };
        separator = " ";
        key = {
          width = 16;
          type = "string";
        };
        constants = [ "────────────" ];
        percent = {
          type = [ "bar" ];
          color = {
            green = "92";
            yellow = "93";
            red = "91";
          };
        };
        bar = {
          width = 16;
        };
      };
      modules = [
        {
          key = "╭{$1}╮";
          type = "custom";
        }
        (mkField 1 "{icon}" "os" "os" { format = "{pretty-name} · {sysname} {kernel-release}"; })
        (mkField 2 "" "packages" "packages" { })
        (mkField 3 "󰍹" "display" "display" { format = "{width}x{height} @ {refresh-rate} Hz"; })
        {
          key = "├{$1}┤";
          type = "custom";
        }
        (mkField 1 "" "user" "title" { format = "{user-name-colored}@{host-name-colored}"; })
        (mkField 2 "󰅐" "uptime" "uptime" { })
        {
          key = "├{$1}┤";
          type = "custom";
        }
        (mkField 5 "" "wm" "wm" { })
        (mkField 6 "󰉼" "theme" "theme" { })
        (mkField 1 "" "icons" "icons" { })
        (mkField 2 "" "term" "terminal" { })
        (mkField 3 "" "shell" "shell" { })
        {
          key = "├{$1}┤";
          type = "custom";
        }
        (mkField 4 "󰍛" "cpu" "cpu" { showPeCoreCount = true; })
        (mkField 5 "󰾲" "gpu" "gpu" { })
        (mkField 6 "" "disk" "disk" {
          folders = "/";
          bar = true;
        })
        (mkField 1 "" "memory" "memory" { })
        (mkField 2 "󰓡" "swap" "swap" { })
        {
          key = "├{$1}┤";
          type = "custom";
        }
        (mkField 7 "" "colors" "custom" {
          format = "\t{#90} {#91} {#92} {#93} {#94} {#95} {#96} {#97}   {#37} {#36} {#35} {#34} {#33} {#32} {#31} {#30}";
        })
        {
          key = "╰{$1}╯";
          type = "custom";
        }
      ];
    };
}
