# modules/apps/games.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    lutris
    prismlauncher
    protonup-rs
    wine
    winetricks
    vkd3d
  ];
}
