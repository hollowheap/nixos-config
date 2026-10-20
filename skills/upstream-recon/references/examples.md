# Upstream-Recon Examples

## Bad
- Guessing service option names like `services.caddy.virtualHosts.<host>.reverseProxy` without verifying nixpkgs module declarations.
- Adding a package to `environment.systemPackages` assuming its package name matches the binary name without checking `meta.mainProgram`.

## Good
- Inspect `options.services.caddy` via nix eval, read declaration files in `/nix/store`, and write verified virtual host config.
