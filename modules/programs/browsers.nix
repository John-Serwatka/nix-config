# modules/programs/browsers.nix — web browsers
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    brave
    firefox
    chromium
    google-chrome
  ];
}
