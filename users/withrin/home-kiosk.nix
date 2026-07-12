# users/withrin/home-kiosk.nix — slim Home Manager profile for the game kiosks
#
# Selected by `homeProfile = "home-kiosk"` in flake.nix (see lib/mkHost.nix).
# The kiosks' work specialisation exists for game deploys and on-site
# debugging, so this is shell + git plus just enough game tooling — none of
# the desktop stack (gaming/creative/media/PIM/rclone) from home.nix.
{pkgs, ...}: {
  imports = [
    ../../profiles/home/shell.nix
    ../../profiles/home/git.nix
  ];
  home.stateVersion = "26.05";

  # Same identity as the full profile (users/withrin/home.nix).
  programs.git.settings = {
    user.name = "John Serwatka";
    user.email = "jserwatka@pocketlorestudios.com";
  };

  home.packages = with pkgs; [
    # On-site debugging of the deployed game builds.
    claude-code
    godot-mono
    # godot-mono needs the .NET SDK to rebuild C# scripts.
    dotnet-sdk_8

    neovim # shell.nix sets EDITOR=nvim
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
  };
}
