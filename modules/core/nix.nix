# modules/core/nix.nix — Nix daemon settings, flake support, unfree packages
{...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Deduplicate identical files in the store to save disk. Runs on a schedule
  # instead of during every build (auto-optimise-store slows builds and has a
  # history of store-lock issues).
  nix.optimise.automatic = true;

  # Garbage-collect old generations weekly.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
}
