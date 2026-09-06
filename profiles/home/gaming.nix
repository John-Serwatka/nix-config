# profiles/home/gaming.nix — game launchers, compatibility layers, and tools (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/gaming.nix ];
#
# Note: Steam itself is enabled host-side via modules/programs/steam.nix
# (programs.steam.enable), since it needs system-level integration.
{
  pkgs,
  osConfig,
  ...
}: {
  # Lutris via its module rather than as a bare package: it wraps Lutris with
  # the tools below and symlinks the wine builds into
  # ~/.local/share/lutris/runners/wine, so Lutris *discovers* them instead of
  # merely finding them on PATH.
  programs.lutris = {
    enable = true;

    # Must be the same Steam the system runs or the two conflict; the host sets
    # it in modules/programs/steam.nix.
    steamPackage = osConfig.programs.steam.package;

    # The `full` variant for the same reason modules/services/kiosk.nix pins it
    # (see the comment there): nixpkgs defaults sdlSupport/udevSupport off, and
    # without them wine's winebus never sees gamepads. Sharing one wine
    # derivation with the kiosks also means a controller behaves the same when
    # a build is tested here and when it runs on a booth machine.
    winePackages = [pkgs.wineWow64Packages.full];

    # These land inside the Lutris wrapper, not on PATH.
    extraPackages = with pkgs; [
      winetricks
      vkd3d # DirectX 12 over Vulkan
    ];

    # protonPackages is deliberately unset: protonup-rs below manages GE-Proton
    # imperatively under ~/.steam, and the module's proton path wants
    # umu-launcher, which run-local-win already avoids (repo.steampowered.com
    # 403s on the Steam Linux Runtime container).
  };

  home.packages = with pkgs; [
    prismlauncher # Minecraft launcher
    heroic # Epic/GOG launcher
    protonup-rs # Proton-GE updater

    # No bare `wine` here. It was pkgs.wine — 32-bit only — and the justfile's
    # run-local-win recipe documents it as an active hazard: `command -v wine`
    # picked it up and died with "Bad EXE format" on 64-bit builds, so that
    # recipe builds wineWow64Packages.full and prepends it to PATH instead. The
    # Horde of Viscount kiosk path never used this one either; the kiosks get
    # their wine from modules/services/kiosk.nix (enableWine).
  ];
}
