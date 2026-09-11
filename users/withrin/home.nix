# users/withrin/home.nix — Home Manager configuration for withrin
#
# home.username / home.homeDirectory are set by lib/mkHost.nix from the host's
# users list, so they are not repeated here.
{pkgs, ...}: {
  imports = [
    ./desktop-shortcuts.nix
    ../../modules/home/plasma-launchers.nix
    ../../profiles/home/dev.nix
    ../../profiles/home/creative.nix
    ../../profiles/home/gaming.nix
    ../../profiles/home/media.nix
    ../../profiles/home/communication.nix
    ../../profiles/home/productivity.nix
    ../../profiles/home/utilities.nix
    ../../profiles/home/shell.nix
    ../../profiles/home/git.nix
  ];
  home.stateVersion = "25.05";

  # Cloud files now use the Nextcloud client in profiles/home/utilities.nix.
  # Removing the rclone service leaves its credentials and upload cache intact.

  # This list is the source of truth, so activation overwrites whatever is
  # there. Without force, Plasma replacing the symlink (which it does whenever
  # "Open with → always" is used) would leave a numbered .hm-bak behind on
  # every rebuild. The cost is that a default changed in the Plasma UI is
  # silently reverted on the next rebuild: change it here instead.
  xdg.configFile."mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = ["firefox.desktop"];
      "application/xhtml+xml" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
      "x-scheme-handler/steam" = ["steam.desktop"];
      "x-scheme-handler/steamlink" = ["steam.desktop"];
      "x-scheme-handler/spotify" = ["spotify.desktop"];
      "x-scheme-handler/discord" = ["discord.desktop"];
      "application/x-godot-project" = ["godot.desktop"];
    };
  };
  home.sessionVariables.BROWSER = "firefox";

  # Personal git identity; shared git config (aliases, delta, defaults) is in
  # profiles/home/git.nix.
  programs.git.settings = {
    user.name = "John Serwatka";
    user.email = "jserwatka@pocketlorestudios.com";
  };

  # Native installs (e.g. Claude Code) drop binaries here; put it on PATH.
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.packages = with pkgs; [
    bat
  ];
}
