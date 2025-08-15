# modules/apps/games.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    prismlauncher
    lutris
    protonup-rs
    wine
    winetricks
    vkd3d
    heroic
  ];
}
