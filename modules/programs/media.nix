# modules/programs/media.nix — audio and video players
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    spotify
    vlc
  ];
}
