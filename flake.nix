{
  description = "Multi-host NixOS + Home Manager flake with devShell";

  inputs = {
    # Main pkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Unstable nix CLI, pinned to the same nixpkgs
    nixUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixUnstable.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixUnstable, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs   = import nixpkgs { inherit system; };
  in
  {
    formatter.${system} = pkgs.alejandra;
    # Your existing NixOS hosts
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

    # Dev shell for your OpenAI coding environment
    devShells = {
      "${system}" = pkgs.mkShell {
        buildInputs = with pkgs; [
          git
          nixUnstable            # `nix` CLI with flakes support
          home-manager.packages.${system}.home-manager
        ];
        shellHook = ''
          export NIX_CONFIG="experimental-features = nix-command flakes"
          echo "🚀 Dev shell ready: git, nix (flakes), home-manager available"
        '';
      };
    };
  };
}

