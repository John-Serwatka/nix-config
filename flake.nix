{
  description = "Highly modular multi-host NixOS config with Home Manager";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    mkHost = import ./lib/mkHost.nix { inherit nixpkgs home-manager; };
  in {
    nixosConfigurations = {

      desktop = mkHost {
        hostname = "desktop";
        users    = [ "withrin" ];
        modules  = [ ./hosts/desktop/default.nix ];
      };

      laptop = mkHost {
        hostname = "laptop";
        users    = [ "withrin" ];
        modules  = [ ./hosts/laptop/default.nix ];
      };

    };
  };
}
