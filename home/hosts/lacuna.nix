{
  desktop = {
    # The internal panel is not HDR-capable; forcing hdredid washes out SDR colors.
    hdr = false;
    primaryOutput = "eDP-1";

    monitors = [
      {
        output = "eDP-1";
        mode = "2880x1800@120";
        bitdepth = 10;
        cm = "srgb";
      }
    ];

    touchscreen = {
      switchDevice = "Lenovo Yoga Tablet Mode Control switch";
      devices = [
        {name = "wacom-hid-53b7-pen";}
        {name = "wacom-hid-53b7-finger";}
      ];
    };
  };
}
