{ config, pkgs, ... }:

{
  home.username = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion = "24.05";
  home.sessionPath = [ "$HOME/bin" ];
  nixpkgs.config.allowUnfree = true;

  programs.git = {
    enable = true;
    userName = "withriin";
    userEmail = "johnchrisserwatka@gmail.com";
    bash = true;
  };

  programs.bash.enable = true;

  home.packages = import ./shared-packages.nix { inherit pkgs;};

  # Add more shared user config here (dotfiles, aliases, etc.)
}
