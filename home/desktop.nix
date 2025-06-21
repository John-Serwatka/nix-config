 { config, pkgs, ... }:

 {

  imports = [ ./home.nix ];

  # Now override `home.packages` by concatenating shared + desktop-only:
  home.packages = (import ./shared-packages.nix { inherit pkgs; })
               ++ (with pkgs; [
                    ckb-next
                    piper
                    libratbag
                 ]);

  # Any other desktop-specific Home Manager options go here
}
