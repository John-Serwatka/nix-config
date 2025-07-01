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
    jetbrains.idea-ultimate
    gnupg
    pinentry
    kdePackages.plasma-browser-integration
    openjdk21
    firefox
    google-chrome
    kdePackages.kalarm
  ];
}
