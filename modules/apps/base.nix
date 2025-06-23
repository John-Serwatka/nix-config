# modules/apps/base.nix — system-wide packages for all hosts
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    wget
    brave
    spotify
    discord
    neovim
    kdePackages.kate
    obsidian
    _1password-gui
  ];
}
