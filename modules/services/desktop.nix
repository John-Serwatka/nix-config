# modules/services/desktop.nix — KDE Plasma 6 desktop environment with SDDM
{ pkgs, ... }:

{
  services.xserver.enable      = true;
  services.xserver.xkb.layout = "us";

  services.displayManager.sddm.enable      = true;
  services.desktopManager.plasma6.enable   = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kscreen   # Display and Monitor KCM
  ];
}
