{
  description = "Highly modular multi-host NixOS config with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Ollama's CUDA build, deliberately pinned to a fixed revision.
    #
    # `ollama-cuda` is not in cache.nixos.org — Hydra does not publish
    # CUDA-enabled outputs — and cuda-maintainers.cachix.org does not carry it
    # either. So every nixpkgs bump forced a full local ollama+CUDA compile on
    # the desktop; the store still holds 0.30.5, 0.31.1 and 0.33.1 from exactly
    # that. Pinning a *rev* is what stops it. Pinning a stable *branch* would
    # not: stable's ollama-cuda is just as uncached, it would only be hit less
    # often.
    #
    # No `follows` here on purpose — making this track nixpkgs would defeat the
    # entire point of the pin.
    #
    # This is the rev nixpkgs itself was locked to when the pin was introduced,
    # so adopting it rebuilt nothing. Moving it is a deliberate act:
    #   nix flake update nixpkgs-ollama
    # and it costs one long CUDA compile every time.
    nixpkgs-ollama.url = "github:NixOS/nixpkgs/d2f67949798825fe853f7c5d0492b8bf016d3f88";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Encrypted secrets management (see modules/core/sops.nix).
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk partitioning (see modules/disk/kiosk.nix). Used by the
    # kiosks, which get reprovisioned; desktop/laptop keep their hardware.nix.
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-ollama,
    home-manager,
    sops-nix,
    disko,
    ...
  }: let
    system = "x86_64-linux";
    mkHost = import ./lib/mkHost.nix {inherit nixpkgs home-manager sops-nix disko;};

    # Feeds the pinned ollama-cuda (see the nixpkgs-ollama input above) to the
    # hosts that import modules/services/ollama.nix — currently just the
    # desktop. Only that one attribute is overridden, so nothing else on the
    # host is affected and no other package rebuilds.
    ollamaPin = {
      nixpkgs.overlays = [
        (_final: _prev: {
          ollama-cuda =
            (import nixpkgs-ollama {
              inherit system;
              config.allowUnfree = true;
            })
            .ollama-cuda;
        })
      ];
    };
  in {
    # `nix fmt` formats every .nix file with Alejandra.
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations = {
      desktop = mkHost {
        hostname = "desktop";
        users = ["withrin"];
        modules = [./hosts/desktop/default.nix ollamaPin];
      };

      # withrin stays first so it remains myConfig.primaryUser, which is where
      # the sops age keyFile path comes from on a host with no sshd. booth-admin
      # is the low-privilege kiosk-dashboard operator login; both use the default
      # homeProfile = "home", so each has its own users/<name>/home.nix.
      laptop = mkHost {
        hostname = "laptop";
        users = ["withrin" "booth-admin"];
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

      # Second OptiPlex (3070). Shares hosts/optiplex-common.nix with the first
      # but was provisioned with disko from the start, so it has no hardware.nix.
      optiplex2 = mkHost {
        hostname = "optiplex2";
        users = ["withrin"];
        homeProfile = "home-kiosk";
        modules = [./hosts/optiplex2/default.nix];
      };

      # Bootable USB installer carrying this flake (hosts/installer). Not built
      # with mkHost: it has no users of its own, no Home Manager and no secrets
      # — the installation-cd profile supplies its accounts. `self` is passed so
      # the image can embed the flake source it was built from.
      installer = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self disko;};
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
