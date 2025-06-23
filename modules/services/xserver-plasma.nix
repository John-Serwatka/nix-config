# modules/services/xserver-plasma.nix
{ config, pkgs, ... }:

{
  # Enable X11/Wayland support
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  # Enable SDDM at the correct path
  services.displayManager.sddm.enable = true;

  # Enable Plasma 6
  services.desktopManager.plasma6.enable = true;
}
