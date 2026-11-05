{ config, lib, pkgs, ... }:
let
  applyProfile = pkgs.writeShellApplication {
    name = "power-profile-extras";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      iw
    ];
    text = ''
      write() {
        if [ -w "$1" ]; then
          printf '%s\n' "$2" > "$1" || true
        fi
      }

      apply() {
        case "$1" in
          performance)
            write /sys/devices/system/cpu/intel_pstate/no_turbo 0
            write /sys/devices/system/cpu/intel_pstate/max_perf_pct 100
            write /sys/module/pcie_aspm/parameters/policy default
            write /sys/module/snd_hda_intel/parameters/power_save 10
            wifi_power=off
            ;;
          low-power)
            write /sys/devices/system/cpu/intel_pstate/no_turbo 1
            write /sys/devices/system/cpu/intel_pstate/max_perf_pct 50
            write /sys/module/pcie_aspm/parameters/policy powersupersave
            write /sys/module/snd_hda_intel/parameters/power_save 1
            wifi_power=on
            ;;
          *)
            write /sys/devices/system/cpu/intel_pstate/no_turbo 0
            write /sys/devices/system/cpu/intel_pstate/max_perf_pct 100
            write /sys/module/pcie_aspm/parameters/policy default
            write /sys/module/snd_hda_intel/parameters/power_save 10
            wifi_power=off
            ;;
        esac

        if command -v iw >/dev/null 2>&1; then
          iw dev | awk '$1 == "Interface" { print $2 }' | while read -r iface; do
            [ -n "$iface" ] && iw dev "$iface" set power_save "$wifi_power" 2>/dev/null || true
          done
        fi
      }

      last=
      while :; do
        current="$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo balanced)"
        if [ "$current" != "$last" ]; then
          apply "$current"
          last="$current"
        fi
        sleep 5
      done
    '';
  };
in
{
  config = lib.mkIf config.services.power-profiles-daemon.enable {
    systemd.services.power-profile-extras = {
      description = "Apply extra power settings for the active power profile";
      after = [ "power-profiles-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${applyProfile}/bin/power-profile-extras";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
