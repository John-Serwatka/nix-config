# lib/mkHost.nix — builds a NixosSystem with Home Manager wired in per-user
#
# Usage in flake.nix:
#   mkHost = import ./lib/mkHost.nix { inherit nixpkgs home-manager; };
#   desktop = mkHost { hostname = "desktop"; users = [ "withrin" ]; modules = [ ... ]; };
#
# To add a new machine: call mkHost with a new hostname + module list.
# To add a new user:    create users/<name>/home.nix, then add the name to `users`.
#
# `homeProfile` selects which users/<name>/<homeProfile>.nix each user gets —
# e.g. the kiosks pass "home-kiosk" for a slim profile instead of the full
# desktop one.
{
  nixpkgs,
  home-manager,
  sops-nix,
  disko,
}: {
  hostname,
  system ? "x86_64-linux",
  users ? [],
  modules ? [],
  homeProfile ? "home",
}:
nixpkgs.lib.nixosSystem {
  # Platform is declared via nixpkgs.hostPlatform below (upstream's preferred
  # mechanism) rather than nixosSystem's legacy `system` argument.
  modules =
    modules
    # System-level account for each user (users/<name>/default.nix).
    ++ map (user: ../users/${user}/default.nix) users
    ++ [
      ../modules/core/users.nix
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
      # Inert unless a host sets disko.devices (see modules/disk/kiosk.nix), so
      # this costs the desktop and laptop nothing.
      disko.nixosModules.disko
      ({pkgs, ...}: {
        # Overrides the mkDefault in each host's generated hardware.nix
        # (same value today; mkHost stays the single source of truth).
        nixpkgs.hostPlatform = system;

        # Single source of truth for the host's users (see modules/core/users.nix).
        myConfig.users = users;

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Desktop apps can replace managed symlinks with writable files. Keep
        # the latest displaced file at .hm-bak and number older backups so a
        # second activation neither fails nor discards the previous backup.
        home-manager.backupCommand = nixpkgs.lib.getExe (pkgs.writeShellApplication {
          name = "home-manager-backup";
          runtimeInputs = [pkgs.coreutils];
          text = ''
            mv --backup=numbered --no-target-directory -- "$1" "$1.hm-bak"
          '';
        });
        home-manager.users =
          nixpkgs.lib.genAttrs users
          (user: {
            imports = [
              ../users/${user}/${homeProfile}.nix
              ../modules/home/rclone.nix
            ];
            home.username = user;
            home.homeDirectory = "/home/${user}";
          });
      })
    ];
}
