{
  config,
  pkgs,
  ...
}:
let
  zen = config.programs.zen-browser.package;

  webDispatcher = pkgs.writeShellScriptBin "web-dispatcher" ''
    set -euo pipefail
    url="''${1:-}"

    case "$url" in
      *://music.youtube.com|*://music.youtube.com/*)
        exec ${pkgs.pear-desktop}/bin/pear-desktop "$url"
        ;;
      *)
        exec ${zen}/bin/zen-twilight --name zen-twilight "$url"
        ;;
    esac
  '';
in
{
  xdg.desktopEntries.web-dispatcher = {
    name = "Web Dispatcher";
    exec = "${webDispatcher}/bin/web-dispatcher %u";
    icon = "zen-twilight";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Web / Browser
      "text/html" = "web-dispatcher.desktop";
      "text/xml" = "web-dispatcher.desktop";
      "application/xhtml+xml" = "web-dispatcher.desktop";
      "application/vnd.mozilla.xul+xml" = "web-dispatcher.desktop";
      "x-scheme-handler/http" = "web-dispatcher.desktop";
      "x-scheme-handler/https" = "web-dispatcher.desktop";
      "x-scheme-handler/about" = "web-dispatcher.desktop";
      "x-scheme-handler/unknown" = "web-dispatcher.desktop";

      # PDF Documents
      "application/pdf" = "zen-twilight.desktop";

      # Email & Calendar
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "message/rfc822" = "thunderbird.desktop";
      "text/calendar" = "thunderbird.desktop";
      "text/x-vcard" = "thunderbird.desktop";

      # File Manager
      "inode/directory" = "org.gnome.Nautilus.desktop";

      # Terminal
      "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";

      # Documents & Office (LibreOffice)
      "application/vnd.oasis.opendocument.text" = "writer.desktop";
      "application/msword" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "text/plain" = "org.gnome.TextEditor.desktop";

      # Spreadsheets (LibreOffice Calc)
      "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop";
      "application/vnd.ms-excel" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
      "text/csv" = "calc.desktop";

      # Presentations (LibreOffice Impress)
      "application/vnd.oasis.opendocument.presentation" = "impress.desktop";
      "application/vnd.ms-powerpoint" = "impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";

      # Images (Loupe)
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";

      # Audio / Video (mpv)
      "audio/mpeg" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";

      # Messaging & Social
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
    };
  };
}
