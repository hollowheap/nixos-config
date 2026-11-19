# nixos-config
My NixOS configuararion

## Acervus bootstrap

Start the installer with the path where the encrypted shared document will be placed.
After mounting the target, it creates or reuses the permanent SSH host key.
It prints the public age recipient and waits for the shared document.

```sh
nix run .#install-acervus -- acervus \
  --bootstrap-secrets /run/media/installer/common.yaml
```

On the admin workstation, prepare the scoped documents using the printed recipient.

```sh
nix run .#install -- prepare-acervus \
  --recipient 'ACERVUS_PUBLIC_AGE_RECIPIENT' \
  --output ./prepared-acervus
```

Transfer `prepared-acervus/secrets/common.yaml` to the installer path.
The installer validates it with the permanent host key and installs using that ciphertext.
If the install was interrupted after Disko, resume with `--skip-disko` to reuse the mounted host key.

Keep `prepared-acervus/secrets/lacuna.yaml` on the admin side.
Before rebuilding from the repository, promote the prepared SOPS files and update the host modules to use the scoped paths.
