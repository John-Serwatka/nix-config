# modules/home/godot.nix — which Godot engine this user runs
#
# The selection lives on its own because two unrelated modules need it and
# neither should have to import the other: profiles/home/dev.nix installs the
# package, users/withrin/desktop-shortcuts.nix builds the stable
# godot.desktop alias from the same package's own entry. Both import this.
#
# Change this one selection when a project is ready for a newer release;
# patch updates follow the flake lock.
{
  lib,
  pkgs,
  ...
}: {
  options.my.godot.package = lib.mkPackageOption pkgs "godot_4_6-mono" {};
}
