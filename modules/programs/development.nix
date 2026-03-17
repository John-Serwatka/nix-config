# modules/programs/development.nix — editors, IDEs, and developer tooling
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    kdePackages.kate
    kdePackages.plasma-browser-integration
    jetbrains.idea
    pinentry-gnome3
  ];
}
