# modules/core/nix.nix — Nix daemon settings, flake support, unfree packages
{...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Deduplicate identical files in the store to save disk.
  nix.settings.auto-optimise-store = true;

  # Garbage-collect old generations weekly.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;
}
