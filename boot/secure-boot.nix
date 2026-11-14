{ pkgs, ... }:

{
  boot.loader.grub = {
    extraInstallCommands = with pkgs; ''
      if [ ! -f /var/lib/sbctl/keys/db/db.key ]; then
        echo "secure-boot: /var/lib/sbctl/keys/db/db.key not found; skipping EFI signing" >&2
        exit 0
      fi

      if [ -f /boot/EFI/NixOS-boot/grubx64.efi ]; then
        ${sbctl}/bin/sbctl sign /boot/EFI/NixOS-boot/grubx64.efi
      fi

      for efi in /boot/grub/x86_64-efi/*; do
        if [[ -f "$efi" && "$efi" == *.efi ]]; then
          ${sbctl}/bin/sbctl sign "$efi"
        fi
      done

      ${findutils}/bin/find /boot -type f -name "*-bzImage" -exec ${sbctl}/bin/sbctl sign {} +
    '';

    extraGrubInstallArgs = [
      "--disable-shim-lock"
      "--modules=tpm"
    ];
  };
}
