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
          colorCode = toString (color + 30);
          paddedField = padRight 9 " " field;
        in
        {
          key = "│ {#${colorCode}}${icon} ${paddedField}{#keys}│";
          inherit type;
        }
        // opts;
    in
    {
      display = {
        separator = " ";
        key = {
          width = 16;
          type = "string";
        };
        constants = [ "────────────" ];
        percent = {
          type = [ "bar" ];
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
        (mkField 1 "{icon}" "os" "os" { })
        (mkField 2 "" "kernel" "kernel" { })
        (mkField 3 "" "packages" "packages" { })
        (mkField 4 "󰩟" "network" "localip" { format = "{ipv4} ({ifname})"; })
        {
          key = "├{$1}┤";
          type = "custom";
        }
        (mkField 1 "" "user" "title" { format = "{user-name-colored}"; })
        (mkField 2 "" "host" "title" { format = "{host-name-colored}"; })
        (mkField 3 "󰅐" "uptime" "uptime" { })
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
        (mkField 9 "" "colors" "custom" {
          format = "\t{#90} {#31} {#32} {#33} {#34} {#35} {#36} {#37} {#38} {#39}    {#38} {#37} {#36} {#35} {#34} {#33} {#32} {#31} {#90}";
        })
        {
          key = "╰{$1}╯";
          type = "custom";
        }
      ];
    };
}
