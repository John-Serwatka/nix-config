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
    };
  };
}
