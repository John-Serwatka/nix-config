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

  # Kiosk debugging happens over SSH, so this profile installs the editor and
  # owns EDITOR/VISUAL with it (see profiles/home/shell.nix).
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Match what bare `pkgs.neovim` gave us: `wrapNeovim neovim-unwrapped {}`
    # has every provider off. Home Manager still defaults these to `true` under
    # home.stateVersion < 26.05, which would drag Ruby and a pynvim Python into
    # the closure for providers nothing here uses.
    withRuby = false;
    withPython3 = false;
  };

  home.packages = with pkgs; [
    # On-site debugging of the deployed game builds.
    claude-code
    godot-mono
    # godot-mono needs the .NET SDK to rebuild C# scripts.
    dotnet-sdk_8
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
  };
}
