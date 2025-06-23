# modules/services/flatpak.nix
{ config, ... }:

{
  services.flatpak.enable   = true;
  xdg.portal.enable         = true;
  xdg.portal.extraPortals   = with pkgs; [ kdePackages.xdg-desktop-portal-kde ];

+ # Keep <1.17 behavior: use the first portal implementation found
+ xdg.portal.config.common.default = "*";
}
