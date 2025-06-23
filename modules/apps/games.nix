# modules/apps/games.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    lutris
    protonup-rs
    wine
    winetricks
    vkd3d
  ];
}
