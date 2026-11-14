{ config, pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
    extraPackages = with pkgs; [
      ffmpeg
      glow
      ouch
      poppler-utils
      rip2
    ];
    plugins = {
      inherit (pkgs.yaziPlugins) glow ouch;
    };
    settings = {
      opener.extract = [
        {
          run = ''ouch d -y "$@"'';
          desc = "Extract here with ouch";
          for = "unix";
        }
      ];
      plugin.prepend_previewers = [
        {
          mime = "text/markdown";
          run = "glow";
        }
        {
          mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
          run = "ouch";
        }
      ];
    };
    keymap.mgr.prepend_keymap = [
      {
        on = [ "C" ];
        run = "plugin ouch";
        desc = "Compress with ouch";
      }
      {
        on = [ "d" ];
        run = ''shell --confirm -- rip -- "$@"'';
        desc = "Trash selected files with rip2";
      }
      {
        on = [ "U" ];
        run = "shell --block -- rip -u";
        desc = "Undo last rip2 trash in current directory";
      }
    ];
    theme.flavor = {
      dark = "wallust";
      light = "wallust";
    };
  };

  programs.wallust.settings.templates.yazi = {
    template = "flavor.toml";
    target = "${config.xdg.configHome}/yazi/flavors/wallust.yazi/flavor.toml";
  };

  programs.wallust.settings.templates.yazi-tmtheme = {
    template = "bat.tmTheme";
    target = "${config.xdg.configHome}/yazi/flavors/wallust.yazi/tmtheme.xml";
  };

  home.packages = with pkgs; [
    ffmpeg
    glow
    ouch
    poppler-utils
    rip2
  ];
}
