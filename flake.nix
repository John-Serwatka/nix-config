{
  description = "Multi-host NixOS system with Home Manager module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/shared.nix
            ./hosts/desktop.nix
            home-manager.nixosModules.home-manager
            { home-manager.users.withrin = import ./home/desktop.nix; }
          ];
        };
        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/shared.nix
            ./hosts/laptop.nix
            home-manager.nixosModules.home-manager
            { home-manager.users.withrin = import ./home/laptop.nix; }
          ];
        };
      };
    };
}
