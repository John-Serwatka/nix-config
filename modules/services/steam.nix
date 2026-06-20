# modules/services/steam.nix
# Note: unfree is allowed globally in modules/core/nix.nix (allowUnfree = true),
# which already covers steam/steam-run, so no per-package predicate is needed here.
{...}: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # if you use Steam Remote Play
    localNetworkGameTransfers.openFirewall = true;
    # dedicatedServer.openFirewall = true;  # if you run source servers
  };
}
