# Nix Configuration

This flake contains a multi-host NixOS configuration with Home Manager.

## Formatting

Run `nix fmt` to format all Nix files in the repository using the Alejandra
formatter provided by this flake.

## Spotify via Flatpak

If you prefer running Spotify through Flatpak, make sure the Flatpak
service is enabled. This repo sets it globally in `modules/shared.nix`:

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
