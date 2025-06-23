# modules/services/kscreen.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kdeFrameworks.kscreen     # provides the “Display and Monitor” KCM
  ];
}
