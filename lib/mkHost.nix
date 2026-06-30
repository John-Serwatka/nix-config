# lib/mkHost.nix — builds a NixosSystem with Home Manager wired in per-user
#
# Usage in flake.nix:
#   mkHost = import ./lib/mkHost.nix { inherit nixpkgs home-manager; };
#   desktop = mkHost { hostname = "desktop"; users = [ "withrin" ]; modules = [ ... ]; };
#
# To add a new machine: call mkHost with a new hostname + module list.
# To add a new user:    create users/<name>/home.nix, then add the name to `users`.
{
  nixpkgs,
  home-manager,
  sops-nix,
}: {
  hostname,
  system ? "x86_64-linux",
  users ? [],
  modules ? [],
}:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules =
    modules
    # System-level account for each user (users/<name>/default.nix).
    ++ map (user: ../users/${user}/default.nix) users
    ++ [
      ../modules/core/users.nix
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
      {
        # Single source of truth for the host's users (see modules/core/users.nix).
        myConfig.users = users;

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Back up clobbered dotfiles instead of failing activation on them.
        home-manager.backupFileExtension = "hm-bak";
        home-manager.users =
          nixpkgs.lib.genAttrs users
          (user: {
            imports = [
              ../users/${user}/home.nix
              ../modules/services/rclone.nix
            ];
            home.username = user;
            home.homeDirectory = "/home/${user}";
          });
      }
    ];
}
