# lib/mkHost.nix — builds a NixosSystem with Home Manager wired in per-user
#
# Usage in flake.nix:
#   mkHost = import ./lib/mkHost.nix { inherit nixpkgs home-manager; };
#   desktop = mkHost { hostname = "desktop"; users = [ "withrin" ]; modules = [ ... ]; };
#
# To add a new machine: call mkHost with a new hostname + module list.
# To add a new user:    create users/<name>/home.nix, then add the name to `users`.

{ nixpkgs, home-manager }:

{ hostname
, system  ? "x86_64-linux"
, users   ? []
, modules ? []
}:

nixpkgs.lib.nixosSystem {
  inherit system;
  modules = modules ++ [
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs   = true;
      home-manager.useUserPackages = true;
      home-manager.users = nixpkgs.lib.genAttrs users
        ( user: { imports = [
        ../users/${user}/home.nix
        ..modules/services/rclone.nix
        ];
      });
    }
  ];
}
