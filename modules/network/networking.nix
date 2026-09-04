{ config, ... }:

{
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];

    allowedUDPPorts = [ 3478 ];
  };

  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    dns = "systemd-resolved";
    ensureProfiles = {
      environmentFiles = [ config.sops.secrets."wireless_env".path ];
      profiles = {
        "Wired" = {
          connection = {
            id = "Wired";
            type = "ethernet";
          };
        };
        "Home" = {
          connection = {
            id = "Home";
            type = "wifi";
          };
          wifi.ssid = "$HOME_SSID";
          wifi-security = {
            key-mgmt = "sae";
            psk = "$HOME_PSK";
          };
        };
        "Phone" = {
          connection = {
            id = "Phone";
            type = "wifi";
          };
          wifi.ssid = "$PHONE_SSID";
          wifi-security = {
            key-mgmt = "sae";
            psk = "$PHONE_PSK";
          };
        };
        "University" = {
          connection = {
            id = "University";
            type = "wifi";
          };
          wifi.ssid = "$UNI_SSID";
          wifi-security = {
            key-mgmt = "wpa-eap";
          };
          "802-1x" = {
            eap = "peap;";
            identity = "$UNI_IDENTITY";
            password = "$UNI_PSK";
            phase2-auth = "mschapv2";
          };
        };
      };
    };
  };
}
