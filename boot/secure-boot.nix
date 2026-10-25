{ pkgs, ... }:

{
  boot.loader.grub = {
    extraInstallCommands = with pkgs; ''
      if [ -f /boot/EFI/NixOS-boot/grubx64.efi ]; then
        ${sbctl}/bin/sbctl sign /boot/EFI/NixOS-boot/grubx64.efi
      fi

      for efi in /boot/grub/x86_64-efi/*; do
        if [[ -f "$efi" && "$efi" == *.efi ]]; then
          ${sbctl}/bin/sbctl sign $efi
        fi
      done

      for kernel in /boot/kernels/*; do
        if [ -f "$kernel" ]; then
          ${findutils}/bin/find /boot -type f -name "*-bzImage" -exec ${pkgs.sbctl}/bin/sbctl sign {} \;
        fi
      done
    '';

    extraGrubInstallArgs = [
      "--disable-shim-lock"
      "--modules=tpm"
    ];
  };
}
