{
  writeShellApplication,
  systemd,
  glib,
  gnused,
  procps,
}:
writeShellApplication {
  name = "ghostty-reload";
  runtimeInputs = [
    systemd
    glib
    gnused
    procps
  ];
  text = ''
    primary_pid=""
    if command -v systemctl >/dev/null 2>&1; then
      candidate_pid="$(systemctl --user show --property=MainPID --value app-com.mitchellh.ghostty.service 2>/dev/null || true)"
      if [[ "$candidate_pid" =~ ^[1-9][0-9]*$ ]] &&
          systemctl --user reload app-com.mitchellh.ghostty.service >/dev/null 2>&1; then
        primary_pid="$candidate_pid"
      fi
    fi

    if [ -z "$primary_pid" ] && command -v gdbus >/dev/null 2>&1; then
      candidate_pid="$(
        {
          gdbus call --session \
            --dest org.freedesktop.DBus \
            --object-path /org/freedesktop/DBus \
            --method org.freedesktop.DBus.GetConnectionUnixProcessID \
            com.mitchellh.ghostty 2>/dev/null || true
        } | sed -nE 's/^\(uint32 ([0-9]+),\)$/\1/p'
      )"
      if [[ "$candidate_pid" =~ ^[1-9][0-9]*$ ]] &&
          gdbus call --session \
            --dest com.mitchellh.ghostty \
            --object-path /com/mitchellh/ghostty \
            --method org.gtk.Actions.Activate \
            reload-config '[]' '{}' >/dev/null 2>&1; then
        primary_pid="$candidate_pid"
      fi
    fi

    for pid in $(pgrep -f '^([^ ]*/)?\.?ghostty(-wrapped)?( |$)' 2>/dev/null || true); do
      [ "$pid" = "$$" ] && continue
      [ "$pid" = "$primary_pid" ] && continue
      kill -SIGUSR2 "$pid" 2>/dev/null || true
    done
  '';
}
