# users/withrin/home.nix — Home Manager configuration for withrin
#
# home.username / home.homeDirectory are set by lib/mkHost.nix from the host's
# users list, so they are not repeated here.
{pkgs, ...}: {
  imports = [
    ./desktop-shortcuts.nix
  ];
  home.stateVersion = "25.05";

  programs.bash.enable = true;

  my.rclone = {
    enable = true;

    mounts = {
      # mountPoint defaults to ${config.home.homeDirectory}/cloud/pocketlore.
      pocketlore = {
        remote = "PocketLore_gdrive:";
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "John Serwatka";
      user.email = "jserwatka@pocketlorestudios.com";
    };
  };

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
  };

  # Native installs (e.g. Claude Code) drop binaries here; put it on PATH.
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.packages = with pkgs; [
    bat
    syncthingtray # provides the KDE Plasma Syncthing plasmoid (panel widget)
  ];
}
