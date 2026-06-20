# Nix Configuration

This flake contains a multi-host NixOS configuration with Home Manager.

## Formatting

Run `nix fmt` to format all Nix files in the repository using the Alejandra
formatter provided by this flake.

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Plain
files are never read into the config — anything Nix evaluates ends up in the
world-readable `/nix/store`, so secrets are kept encrypted and decrypted at
activation into `/run/secrets/<name>`.

Setup and usage are documented inline in `modules/core/sops.nix`; recipient keys
live in `.sops.yaml` and encrypted material goes under `secrets/`. Until a key
and secrets file exist the secrets layer is inert, so the config still builds.

The Syncthing GUI password must **not** be committed (a stale one already leaked
in git history — rotate it); set it in the Syncthing web UI instead.

## Spotify via Flatpak

If you prefer running Spotify through Flatpak, make sure the Flatpak
service is enabled. This repo sets it in `modules/services/flatpak.nix`:

```nix
services.flatpak.enable = true;
```

After rebuilding, install Spotify with:

```bash
flatpak install flathub com.spotify.Client
```

If you run into issues starting the native `spotify` package, you can try
running it in an FHS environment via:

```bash
steam-run spotify
```

or a custom wrapper such as `buildFHSUserEnv`.
