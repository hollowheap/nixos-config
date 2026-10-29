{ config, ... }:

{
  users.adminExtraGroups = [ "networkmanager" ];

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
        "Home 2" = {
          connection = {
            id = "Home 2";
            type = "wifi";
          };
          wifi.ssid = "$HOME2_SSID";
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$HOME2_PSK";
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
