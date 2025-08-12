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
    pinentry
    kdePackages.plasma-browser-integration
    firefox
    google-chrome
    kdePackages.kalarm
    gnome-pomodoro
    kdePackages.kaccounts-integration
    kdePackages.kaccounts-providers
    kdePackages.akonadi
    kdePackages.akonadi-mime
    kdePackages.korganizer
    kdePackages.kdepim-addons
    kdePackages.kmail
    kdePackages.kdepim-runtime
    usbutils
    udiskie
    udisks
    chromium
    lm_sensors
    vlc
    syncthing
    syncthingtray
    jetbrains.idea-ultimate
  ];
}
