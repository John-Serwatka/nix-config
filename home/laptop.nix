# home/laptop.nix
{ config, pkgs, ... }:

{
  imports = [ ./home.nix ];

  home.packages = (import ./shared-packages.nix { inherit pkgs; })
               ++ (with pkgs; [
                    tlp
                    acpi_call
                 ]);

  # laptop‐only HM options…
}
