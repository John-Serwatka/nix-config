{
  description = "Multi-host NixOS system with Home Manager module (system-agnostic style, per-host user config)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/shared.nix         # Shared system config for all hosts
          ./hosts/desktop.nix          # Desktop-specific system config
          home-manager.nixosModules.home-manager
          { home-manager.users.withrin = import ./home/desktop.nix; }  # Desktop user config
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/shared.nix
          ./hosts/laptop.nix
          home-manager.nixosModules.home-manager
          { home-manager.users.withrin = import ./home/laptop.nix; }   # Laptop user config
        ];
      };
    };
  };
}
