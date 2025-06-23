# home.nix — all your old shared user config
{ config, pkgs, ... }:

{
  home.username    = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion  = "24.05";

  nixpkgs.config.allowUnfree = true;
   programs.bash.enable = true;

  programs.git = {
    enable    = true;
    userName  = "withriin";
    userEmail = "johnchrisserwatka@gmail.com";
  };

  # …any other programs/services you had…

  home.packages = with pkgs; [
    bat
    #exa
    # add more personal CLI tools here
  ];
}
