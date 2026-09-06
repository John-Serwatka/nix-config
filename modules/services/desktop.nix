# modules/services/desktop.nix — KDE Plasma 6 desktop environment with SDDM
{...}: {
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  services.displayManager.sddm.enable = true;

  # Pulls in the whole Plasma package set, so nothing is listed here by hand:
  # kscreen (the Display and Monitor KCM), kate, and the KDE PIM base packages
  # via programs.kde-pim all arrive with it.
  services.desktopManager.plasma6.enable = true;
}
