{ ... }:
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Web / Browser
      "text/html" = "zen-twilight.desktop";
      "text/xml" = "zen-twilight.desktop";
      "application/xhtml+xml" = "zen-twilight.desktop";
      "application/vnd.mozilla.xul+xml" = "zen-twilight.desktop";
      "x-scheme-handler/http" = "zen-twilight.desktop";
      "x-scheme-handler/https" = "zen-twilight.desktop";
      "x-scheme-handler/about" = "zen-twilight.desktop";
      "x-scheme-handler/unknown" = "zen-twilight.desktop";

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
      "text/plain" = "writer.desktop";

      # Spreadsheets (LibreOffice Calc)
      "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop";
      "application/vnd.ms-excel" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
      "text/csv" = "calc.desktop";

      # Presentations (LibreOffice Impress)
      "application/vnd.oasis.opendocument.presentation" = "impress.desktop";
      "application/vnd.ms-powerpoint" = "impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";

      # Images (Satty)
      "image/png" = "satty.desktop";
      "image/jpeg" = "satty.desktop";
      "image/gif" = "satty.desktop";
      "image/webp" = "satty.desktop";
      "image/bmp" = "satty.desktop";
      "image/svg+xml" = "satty.desktop";

      # Audio / Music
      "audio/mpeg" = "com.github.th-ch.youtube-music.desktop";
      "audio/ogg" = "com.github.th-ch.youtube-music.desktop";
      "audio/flac" = "com.github.th-ch.youtube-music.desktop";
      "audio/wav" = "com.github.th-ch.youtube-music.desktop";
      "audio/x-matroska" = "com.github.th-ch.youtube-music.desktop";

      # Messaging & Social
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
    };
  };
}
