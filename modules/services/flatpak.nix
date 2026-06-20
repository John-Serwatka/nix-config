# modules/services/flatpak.nix
{
  config,
  pkgs,
  ...
}: {
  services.flatpak.enable = true;

  # enable XDG desktop portals…
  xdg.portal.enable = true;

  # …and install the KDE portal to back it
  xdg.portal.extraPortals = with pkgs; [
    kdePackages.xdg-desktop-portal-kde
  ];

  xdg.portal.config.common.default = "*";
}
