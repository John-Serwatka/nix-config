# users/withrin/home.nix — Home Manager configuration for withrin
{ pkgs, ... }:

{
  home.username      = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion  = "25.05";

  programs.bash.enable = true;

  programs.git = {
    enable = true;

    settings = {
        user = {
            name  = "withriin";
            email = "johnchrisserwatka@gmail.com";
        };
    };
  };

  home.packages = with pkgs; [
    bat
  ];
}
