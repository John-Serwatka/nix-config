# users/withrin/home.nix — Home Manager configuration for withrin
{ pkgs, ... }:

{
  home.username      = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion  = "25.05";

  nixpkgs.config.allowUnfree = true;

  programs.bash.enable = true;

  programs.git = {
    enable    = true;
    userName  = "withriin";
    userEmail = "johnchrisserwatka@gmail.com";
  };

  home.packages = with pkgs; [
    bat
  ];
}
