# modules/services/syncthing.nix — Syncthing file sync daemon
#
# Set `myConfig.syncthingUser` in the host to configure which user runs Syncthing.
# Example:  myConfig.syncthingUser = "withrin";
#
# This only runs the daemon. On KDE Plasma, the GUI is the Syncthing plasmoid
# (shipped by pkgs.syncthingtray, installed in the user's home-manager profile),
# added to the panel via "Add Widgets" — not the standalone tray app, which
# Syncthing Tray itself recommends against on Plasma.
{
  config,
  lib,
  ...
}:
with lib; {
  options.myConfig.syncthingUser = mkOption {
    type = types.str;
    description = "Username to run Syncthing for (sets dataDir and configDir).";
  };

  config = {
    services.syncthing = {
      enable = true;
      user = config.myConfig.syncthingUser;
      dataDir = "/home/${config.myConfig.syncthingUser}/Sync";
      configDir = "/home/${config.myConfig.syncthingUser}/.config/syncthing";
      openDefaultPorts = true;
    };
  };
}
