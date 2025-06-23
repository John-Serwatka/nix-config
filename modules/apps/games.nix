# modules/apps/games.nix
{ pkgs, … }:

{
  environment.systemPackages = with pkgs; [
    steam
    lutris
    proton
    wine
    winetricks
    vkd3d
  ];
}
