{
  description = "Highly modular multi-host NixOS config with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Encrypted secrets management (see modules/core/sops.nix).
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux";
    mkHost = import ./lib/mkHost.nix {inherit nixpkgs home-manager sops-nix;};
  in {
    # `nix fmt` formats every .nix file with Alejandra.
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations = {
      desktop = mkHost {
        hostname = "desktop";
        users = ["withrin"];
        modules = [./hosts/desktop/default.nix];
      };

      laptop = mkHost {
        hostname = "laptop";
        users = ["withrin"];
        modules = [./hosts/laptop/default.nix];
      };

      # Game kiosks (see hosts/kiosk-common.nix). The kiosk session user is
      # created by modules/services/kiosk.nix, not listed here — `users` only
      # holds accounts that get a Home Manager profile. withrin gets the slim
      # deploy/debug profile (users/withrin/home-kiosk.nix), not the desktop one.
      optiplex = mkHost {
        hostname = "optiplex";
        users = ["withrin"];
        homeProfile = "home-kiosk";
        modules = [./hosts/optiplex/default.nix];
      };

      beelink = mkHost {
        hostname = "beelink";
        users = ["withrin"];
        homeProfile = "home-kiosk";
        modules = [./hosts/beelink/default.nix];
      };

      # Bootable USB installer carrying this flake (hosts/installer). Not built
      # with mkHost: it has no users of its own, no Home Manager and no secrets
      # — the installation-cd profile supplies its accounts. `self` is passed so
      # the image can embed the flake source it was built from.
      installer = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self;};
        modules = [
          ./hosts/installer/default.nix
          {nixpkgs.hostPlatform = system;}
        ];
      };
    };

    # `nix build .#installer` → result/iso/*.iso
    packages.${system}.installer =
      self.nixosConfigurations.installer.config.system.build.isoImage;
  };
}
