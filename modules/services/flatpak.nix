# modules/services/flatpak.nix — Flatpak runtime
#
# An escape hatch, not a second package manager: anything available in nixpkgs
# belongs in a profiles/home/* profile, where it is declarative and rolls back
# with the generation. Flatpak covers what nixpkgs does not carry, or what needs
# a vendor build. Nothing is installed from here — Flatpak apps are added by
# hand and live outside the flake.
#
# The XDG desktop portal is deliberately NOT configured here. Every host that
# imports this also imports ../services/desktop.nix, and plasma6 already sets
# xdg.portal.enable, adds the KDE and GTK portals to extraPortals, and points
# configPackages at plasma-workspace — which ships the portal preference file
# that decides *which* backend answers each interface. On hosts that also import
# ./cosmic.nix, COSMIC adds its own portal and preference file the same way;
# the files are keyed per desktop, so the two merge without conflict.
#
# This module used to repeat those and add `xdg.portal.config.common.default =
# "*"`. That last one is worse than nothing here: "*" means "any backend that
# implements the interface", which overrides plasma-workspace's ordered
# preferences with whatever happens to be first.
#
# If this is ever imported by a host with no Plasma, the flatpak module's own
# assertion ("To use Flatpak you must enable XDG Desktop Portals") fails the
# build with that exact message — a loud failure, not a silent one.
{...}: {
  services.flatpak.enable = true;
}
