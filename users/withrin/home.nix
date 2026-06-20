# users/withrin/home.nix — Home Manager configuration for withrin
{pkgs, ...}: {
  imports = [
    ./desktop-shortcuts.nix
  ];
  home.username = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion = "25.05";

  programs.bash.enable = true;

  my.rclone = {
    enable = true;

    mounts = {
      pocketlore = {
        remote = "PocketLore_gdrive:";
        mountPoint = "/home/withrin/cloud/pocketlore";
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

  home.packages = with pkgs; [
    bat
  ];
}
